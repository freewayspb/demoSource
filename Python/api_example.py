class RuleFilter(df.FilterSet):
    has_mfo_with_errors = df.BooleanFilter(method='mfo_with_errors_filter')

    def mfo_with_errors_filter(self, queryset, name, value):
        if value:
            lookup = {'count_mfo_with_errors__gt': 0}
        else:
            lookup = {'count_mfo_with_errors__exact': 0}

        return queryset.filter(**lookup)

    class Meta:
        model = Rule
        fields = ['is_active']

##########################################################################

class RuleViewSet(viewsets.ModelViewSet):
    queryset = Rule.objects.select_related('user_created', 'user_changed')
    serializer_class = RuleSerializer
    permission_classes = (permissions.BkiAllPerm,)
    pagination_class = BkiPagination
    ordering_fields = (
        'name', 'dt_created', 'user_created__full_name', 'user_changed__full_name', 'is_active',
        'days_period', 'min_body', 'max_body', 'loan_type', 'loans_per_file', 'board_date',
        'count_mfo', 'count_mfo_with_errors', 'id'
    )
    filter_class = RuleFilter

    def get_queryset(self):
        qs = super(RuleViewSet, self).get_queryset()
        # if self.action == 'list':
        qs = qs.annotate(
            count_mfo=Count('rulelp'),
            count_mfo_with_errors=Sum(
                Case(When(rulelp__status=LP_SENT_STATUS.ERROR, then=1),
                     When(rulelp__status=LP_SENT_STATUS.NOT_ACCEPTED, then=1),
                     default=0, output_field=IntegerField()))
        ).order_by('-dt_created')

        return qs

    def perform_destroy(self, instance):
        # deactivate instead of deleting from db
        instance.is_active = False
        instance.save()

    def _get_action_log_data(self, rule_name, action):
        return {
            'rule': rule_name,
            'action_name': action,
            'dt': datetime.now(),
            'user_id': self.request.user.user_id,
            'user_name': self.request.user.full_name
        }

    def perform_create(self, serializer):
        super(RuleViewSet, self).perform_create(serializer)
        action_log_data = self._get_action_log_data(serializer.validated_data['name'],
                                                    u'Создание правила')
        mf_log.delay(settings.BKI_RULE_ACTION_LOG, action_log_data)

    def perform_update(self, serializer):
        old_data = RuleChangeLogSerializer(serializer.instance).data
        super(RuleViewSet, self).perform_update(serializer)
        new_data = RuleChangeLogSerializer(serializer.instance).data
        if old_data['is_active'] != new_data['is_active']:
            action = u'Активация правила' if new_data['is_active'] else u'Деактивация правила'
            action_log_data = self._get_action_log_data(old_data['name'], action)
            mf_log.delay(settings.BKI_RULE_ACTION_LOG, action_log_data)

        for param, old_value in old_data.items():
            if new_data[param] != old_value:
                changes_log_data = {
                    'rule': old_data['name'],
                    'parameter_name': serializer.instance._meta.get_field(param).verbose_name,
                    'old_value': old_value,
                    'new_value': new_data[param],
                    'dt': datetime.now(),
                    'user_id': self.request.user.user_id,
                    'user_name': self.request.user.full_name
                }
                mf_log.delay(settings.BKI_RULE_CHANGE_LOG, changes_log_data)

    @detail_route(methods=['post'])
    def add_legal_person(self, request, pk=None):
        rule = self.get_object()
        serializer = ListOfLegalPersonSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        pks = serializer.validated_data['legal_persons']
        rule.add_legal_persons(pks)
        action_log_data = self._get_action_log_data(rule.name, u'Добавление МФО в правило')
        mf_log.delay(settings.BKI_RULE_ACTION_LOG, action_log_data)
        return Response(serializer.data)

    @detail_route(methods=['post'])
    def remove_legal_person(self, request, pk=None):
        rule = self.get_object()
        serializer = ListOfLegalPersonSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        pks = serializer.validated_data['legal_persons']
        rule.remove_legal_persons(pks)
        action_log_data = self._get_action_log_data(rule.name, u'Удаление МФО из правила')
        mf_log.delay(settings.BKI_RULE_ACTION_LOG, action_log_data)
        return Response(serializer.data)

    @detail_route(methods=['get'])
    def available_legal_persons(self, request, pk=None):
        """Returns list of legal persons which can be added to rule"""
        rule = self.get_object()
        serializer = LegalPersonMiniSerializer(rule.get_available_legal_persosns(), many=True)
        return Response(serializer.data)


class RuleLpViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = RuleLP.objects.filter(is_active=True).select_related('rule', 'legal_person').order_by('-last_sent_file_dt')
    serializer_class = RuleLpSerializer
    permission_classes = (permissions.BkiAllPerm,)
    pagination_class = BkiPagination
    filter_fields = ('rule', 'status')
    ordering_fields = (
        'legal_person__internal_name', 'status', 'last_sent_file_name',
        'last_sent_file_dt', 'legal_person__bki_key_expire_date'
    )
