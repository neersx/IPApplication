angular.module('Inprotech.Integration.PtoAccess')
    .component('ipScheduleRecoverableCasesAlert', {
        templateUrl: 'condor/classic/integration/ptoaccess/schedule-recoverable-cases-alert.html',
        bindings: {
            model: '<'
        },
        controllerAs: 'vm',
        controller: function ($http, url, notificationService, modalService) {
            'use strict';

            var vm = this;

            vm.$onInit = onInit;

            function onInit() {
                _.extend(vm, vm.model);
                vm.showRecoverableCasesHint = showRecoverableCasesHint;
                vm.showRecoverableCases = showRecoverableCases;
                vm.showRecoverableDocumentsHint = showRecoverableDocumentsHint;
                vm.showRecoverableDocuments = showRecoverableDocuments;
                vm.recover = recover;
                vm.disabledSchedule = vm.schedule.state === 'disabled';
            }

            function showRecoverableCasesHint() {
                return vm.disabledSchedule !== true && (vm.recoveryScheduleStatus !== 'Idle' || (vm.recoveryScheduleStatus === 'Idle' && vm.recoverableCasesCount > 0));
            }

            function showRecoverableCases() {
                modalService.openModal({
                    id: 'RecoverableCases',
                    controllerAs: 'vm',
                    model: {
                        recoverableCases: vm.recoverableCases,
                        hasCorrelationId: vm.hasCorrelationId,
                        dataSource: vm.schedule.dataSource
                    }
                });
            }

            function showRecoverableDocumentsHint() {
                return vm.disabledSchedule !== true && (vm.recoveryScheduleStatus !== 'Idle' || (vm.recoveryScheduleStatus === 'Idle' && vm.recoverableDocumentsCount > 0));
            }

            function showRecoverableDocuments() {
                modalService.openModal({
                    id: 'RecoverableDocuments',
                    controllerAs: 'vm',
                    model: {
                        recoverableDocuments: vm.recoverableDocuments,
                        hasCorrelationId: vm.hasCorrelationId,
                        dataSource: vm.schedule.dataSource
                    }
                });
            }
            function recover() {
                $http.post(url.api('ptoaccess/schedules/' + vm.schedule.id + '/recovery'))
                    .then(function () {
                        notificationService.success('dataDownload.schedule.recoveryIssued');
                        vm.recoveryScheduleStatus = 'Pending';
                    });
            }
        }
    });