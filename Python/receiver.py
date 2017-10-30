# coding=utf-8
import email
import imaplib
import logging
import os
import pickle
import re
import subprocess
from collections import namedtuple
from datetime import date

from django.conf import settings

from main.models import SentFile
from main.utils import lock, get_redis
from main.consts import *


logger = logging.getLogger('main')

LAST_SUCCESS_FETCH_KEY = 'bki_last_success_email_fetch'
TODAY_PROCESSED_MSG_IDS_KEY = 'processed_msg_ids_%s'
SUCCESS = 'OK'


ParsedEmail = namedtuple('ParsedEmail', ['filename', 'file_data', 'status'])


class BkiReceiver(object):
    """Получение ответов от БКИ"""

    def __init__(self, file_names=None):
        # список файлов ожидающих ответа от БКИ
        if file_names is None:
            self.file_names = set(SentFile.objects.filter(status=FILE_STATUS.SENT)
                                  .values_list('file_name', flat=True))
        else:
            self.file_names = file_names

    def get_last_fetch_date(self):
        """
        Returns
        -------
        str
            дата последнего успешного получения ответов от БКИ
        """
        redis = get_redis()
        # return '26-Jan-2016'
        return redis.get(LAST_SUCCESS_FETCH_KEY) or '01-Oct-2016'

    def set_last_fetch_date(self, fetch_date):
        """Устанавливает дату последнего успешного получения ответов от БКИ в redis
        Parameters
        ----------
        fetch_date : datetime.date
        """
        redis = get_redis()
        redis.set(LAST_SUCCESS_FETCH_KEY, fetch_date.strftime('%d-%b-%Y'))

    def get_today_processed_msg_ids(self):
        """
        Returns
        -------
        list
            список id email обработынных за сегодня
        """
        redis = get_redis()
        key = TODAY_PROCESSED_MSG_IDS_KEY % date.today().strftime('%Y-%m-%d')
        ids_str = redis.get(key)
        return pickle.loads(ids_str) if ids_str else []

    def set_today_processed_msg_ids(self, msg_ids):
        """Устанавливает список id email обработанных за сегодня в redis
        Parameters
        ----------
        msg_ids
            список id email
        """
        redis = get_redis()
        key = TODAY_PROCESSED_MSG_IDS_KEY % date.today().strftime('%Y-%m-%d')
        return redis.setex(key, 24 * 60 * 60, pickle.dumps(msg_ids))

    def parse_bki_email(self, data):
        """Парсит email от БКИ
        Parameters
        ----------
        data : str
               email сообщение

        Returns
        -------
        ParsedEmail
        """
        msg = email.message_from_string(data)
        subject_str, encoding = email.header.decode_header(msg['Subject'])[0]
        subject_unicode = subject_str.decode(encoding)
        # print subject_unicode
        # извлекаем имя файла и статус ответа из темы письма
        res = re.search(ur'Re: Кредитная история (\d+_\d+).*(File\w+)', subject_unicode)
        if not res:
            # если не найдены значит это какое-то другое письмо от БКИ(а не ответ на наш файл)
            return

        filename = res.group(1)
        if filename not in self.file_names:
            return

        status = res.group(2)
        file_data = self.extract_file_from_email_if_exists(msg)
        return ParsedEmail(filename, file_data, status)

    def extract_file_from_email_if_exists(self, msg):
        """Извлекает 1-й приложенный файл из email, если ничего не находит возвращает исходный msg
        Parameters
        ----------
        msg : str or email message object

        Returns
        -------
        str
            содержание файла
        """
        if isinstance(msg, str):
            msg = email.message_from_string(msg)

        for part in msg.walk():
            if part.get_content_maintype() == 'multipart':
                continue
            if part.get('Content-Disposition') is None:
                continue
            if not part.get_filename():
                continue

            return part.get_payload(decode=True)
        # if no file found, return original message
        return msg.get_payload(decode=True)

    def decrypt_file(self, parsed_email):
        """Расшифровывает и проверяет подпись ответа от БКИ.
        Parameters
        ----------
        parsed_email : ParsedEmail

        Return
        ----------
           decrypted file content as string
        """
        with lock('bki_decrypt'):
            with open(settings.RECEIVER_ENCRYPTED_FILE, 'w') as f:
                f.write(parsed_email.file_data)

            log = SentFile.objects.get(status=FILE_STATUS.SENT, file_name=parsed_email.filename)

            # расшифровываем
            key_file_path = os.path.join(settings.BKI_PRIVATE_FOLDER,
                                         log.legal_person.bki_key.name)
            # key_file_path = '/home/kir/Downloads/bki/private_keys_p12/2016/galaktika.pem'
            return_code = subprocess.call([
                settings.OPENSSL_PATH, 'smime', '-decrypt', '-engine', 'gost', '-gost89',
                '-binary', '-inform', 'DER', '-in', settings.RECEIVER_ENCRYPTED_FILE,
                '-out', settings.RECEIVER_SIGNED_FILE, '-recip', key_file_path
            ])
            if return_code != 0:
                # файл не зашифрован
                file_path = settings.RECEIVER_ENCRYPTED_FILE
            else:
                # предполагаем, что файл зашифрован и подписан
                file_path = settings.RECEIVER_XML_FILE
                # проверяем подпись
                verify_sign_args = [
                    '/usr/bin/openssl', 'smime', '-verify', '-in', settings.RECEIVER_SIGNED_FILE,
                    '-out', settings.RECEIVER_XML_FILE, '-noverify',
                    '-certfile', settings.BKI_PUBLIC_KEY,
                ]
                return_code = subprocess.call(verify_sign_args)
                if return_code != 0:
                    # почему-то приходят разные форматы, так что попробуем немного подругому
                    verify_sign_args += ['-inform', 'DER']
                    return_code = subprocess.call(verify_sign_args)
                    if return_code != 0:
                        # не удалось проверить подпись - значит файл не подписан
                        file_path = settings.RECEIVER_SIGNED_FILE

            with open(file_path, 'r') as f:
                file_data = f.read()

            return self.extract_file_from_email_if_exists(file_data)

    def get_responses(self):
        """yields bki responses"""
        if not self.file_names:
            logger.info('Bki: no files wait for response, terminating')
            return

        conn = imaplib.IMAP4_SSL(settings.BKI_IMAP_HOST)
        try:
            conn.login(settings.BKI_EMAIL_USERNAME, settings.BKI_EMAIL_PASSWORD)
            conn.select()
            # ищем нужные emails
            status, msg_ids = conn.search(
                None,
                settings.IMAP_SEARCH_CRITERIA % (settings.BKI_TO_EMAIL, self.get_last_fetch_date())
            )
            if status != SUCCESS:
                logger.error('Bki: email search error: %s' % msg_ids)
                return
            # получаем и обрабатываем найденные emails
            for msg_id in msg_ids[0].split():
                if SentFile.objects.filter(response_email_id=msg_id).exists():
                    continue

                status, data = conn.fetch(msg_id, '(RFC822)')
                if status != SUCCESS:
                    logger.error('Bki: failed to fetch a message %s' % msg_id)
                    continue

                parsed_email = self.parse_bki_email(data[0][1])
                if parsed_email:
                    logger.info('Bki: parsing email: %s %s ' % (parsed_email.filename,
                                                                parsed_email.status))
                    yield (parsed_email.filename, parsed_email.status,
                           self.decrypt_file(parsed_email), msg_id)

            self.set_last_fetch_date(date.today())
        finally:
            conn.close()


class ReceiverPlainXml(BkiReceiver):
    """Receives plain xml(not encrypted). Needed for tests."""
    def decrypt_file(self, parsed_email):
        return self.extract_file_from_email_if_exists(parsed_email.file_data)
