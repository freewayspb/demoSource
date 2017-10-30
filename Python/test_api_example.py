class CasesApi(BaseCase):
    def setUp(self):
        self.mf_log = patch('main.views.mf_log')
        self.mf_log.start()
        super(CasesApi, self).setUp()
        user = 'test_user'
        password = '111'
        self.user = G(MFUser, username=user, user_id=None, is_superuser=True)
        self.user.set_password(password)
        self.user.save()
        self.client.force_authenticate(user=self.user)
        assert self.client.login(username='test_user', password='111')

    def tearDown(self):
        self.mf_log.stop()

    def test_login_page(self):
        response = self.client.get(reverse('login'))
        self.assertEqual(response.status_code, st.HTTP_200_OK)

    # test RuleViewSet
    def test_rule_list(self):
        rule1 = G(Rule, is_active=True, loan_type=LOAN_TYPE.FIRST)
        G(RuleLP, rule=rule1, status=LP_SENT_STATUS.ERROR)
        G(RuleLP, rule=rule1, status=LP_SENT_STATUS.ERROR)
        G(RuleLP, rule=rule1, status=LP_SENT_STATUS.WAIT_BKI)
        rule2 = G(Rule, is_active=False, loan_type=LOAN_TYPE.SECOND)
        data = self.client.get(reverse('rule-list'), {'ordering': 'id'}).data['results']
        self.assertEqual(data[0]['id'], rule1.id)
        self.assertEqual(data[0]['loan_type_display'], u'Первичные')
        self.assertEqual(data[0]['count_mfo'], 3)
        self.assertEqual(data[0]['count_mfo_with_errors'], 2)
        self.assertEqual(data[1]['id'], rule2.id)
        self.assertEqual(data[1]['loan_type_display'], u'Повторные')
        self.assertEqual(data[1]['count_mfo'], 0)
        # test sorting by computed field
        data = self.client.get(reverse('rule-list'), {'ordering': '-count_mfo'}).data['results']
        self.assertEqual(data[0]['id'], rule1.id)
        self.assertEqual(data[1]['id'], rule2.id)
        # test filtering
        data = self.client.get(reverse('rule-list'), {'is_active': False}).data['results']
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]['id'], rule2.id)

        data = self.client.get(reverse('rule-list'), {'has_mfo_with_errors': True}).data['results']
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]['id'], rule1.id)

    def test_create_rule(self):
        data = {
            'name': u'Правило буравчика',
            'days_period': 5,
            'min_body': 100,
            'max_body': 1000,
            'loan_type': LOAN_TYPE.FIRST,
            'loans_per_file': 500
        }
        resp = self.client.post(reverse('rule-list'), data, format='json')
        self.assertEqual(resp.status_code, st.HTTP_201_CREATED)
        rule1 = Rule.objects.get()
        self.assertEqual(rule1.name, data['name'])
        # these fields should get default values
        self.assertEqual(rule1.user_created, self.user)
        self.assertEqual(rule1.user_changed, self.user)
        self.assertTrue(rule1.is_active)
        self.assertIsNotNone(rule1.dt_created)
        self.assertEqual(rule1.board_date, date.today() - timedelta(2))

    def test_change_rule(self):
        rule1 = G(Rule)
        data = {
            'name': u'Правило',
            'days_period': 1,
            'min_body': 100,
            'max_body': 1000,
            'loan_type': LOAN_TYPE.SECOND,
            'loans_per_file': 500
        }
        resp = self.client.put(reverse('rule-detail', kwargs={'pk': rule1.pk}),
                               data, format='json')
        self.assertEqual(resp.status_code, st.HTTP_200_OK)
        rule1.refresh_from_db()
        self.assertEqual(rule1.name, data['name'])
        self.assertEqual(rule1.loans_per_file, data['loans_per_file'])
        self.assertEqual(rule1.user_changed, self.user)

    def test_deactivate_rule(self):
        rule1 = G(Rule, is_active=True, name='name1')
        resp = self.client.patch(reverse('rule-detail', kwargs={'pk': rule1.pk}),
                                 {'is_active': False}, format='json')
        self.assertEqual(resp.status_code, st.HTTP_200_OK)
        rule1.refresh_from_db()
        # check rule is deactivated
        self.assertFalse(rule1.is_active)
        # but other fields are not changed
        self.assertEqual(rule1.name, 'name1')

    def test_delete_rule(self):
        rule1 = G(Rule, is_active=True)
        resp = self.client.delete(reverse('rule-detail', kwargs={'pk': rule1.pk}))
        self.assertEqual(resp.status_code, st.HTTP_204_NO_CONTENT)
        rule1.refresh_from_db()
        self.assertFalse(rule1.is_active)

    def test_rule_add_legal_person(self):
        rule1 = G(Rule)
        lp1 = G(LegalPerson)
        lp2 = G(LegalPerson)
        resp = self.client.post(reverse('rule-add-legal-person', kwargs={'pk': rule1.pk}),
                                {'legal_persons': [lp1.pk, lp2.pk]}, format='json')
        self.assertEqual(resp.status_code, st.HTTP_200_OK)
        rulelps = RuleLP.objects.order_by('legal_person')
        self.assertEqual(len(rulelps), 2)
        self.assertEqual(rulelps[0].legal_person_id, lp1.pk)
        self.assertEqual(rulelps[1].legal_person_id, lp2.pk)

    def test_rule_remove_legal_person(self):
        rule1 = G(Rule)
        lp1 = G(LegalPerson)
        lp2 = G(LegalPerson)
        G(RuleLP, rule=rule1, legal_person=lp1, is_active=True)
        G(RuleLP, rule=rule1, legal_person=lp2, is_active=True)
        resp = self.client.post(reverse('rule-remove-legal-person', kwargs={'pk': rule1.pk}),
                                {'legal_persons': [lp1.pk]}, format='json')

        self.assertEqual(resp.status_code, st.HTTP_200_OK)
        rulelps = RuleLP.objects.order_by('legal_person')
        self.assertEqual(len(rulelps), 2)
        self.assertEqual(rulelps[0].is_active, False)
        self.assertEqual(rulelps[1].is_active, True)

    def test_rule_available_legal_persons(self):
        rule1 = G(Rule)
        lp1 = G(LegalPerson, internal_name='n1')
        resp = self.client.get(reverse('rule-available-legal-persons', kwargs={'pk': rule1.pk}))
        self.assertEqual(resp.status_code, st.HTTP_200_OK)
        self.assertEqual(resp.data[0]['id'], lp1.id)
        self.assertEqual(resp.data[0]['internal_name'], lp1.internal_name)
