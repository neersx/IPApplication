angular.module('Inprotech.Integration.ExternalApplication')
    .controller('externalApplicationTokenEditController', ['http', 'options', 'url', '$uibModalInstance', 'notificationService',
        function (http, options, url, $uibModalInstance, notificationService) {

            'use strict';
            var vm = this;
            vm.form = {}
            var dt = new Date();
            vm.minStartDate = dt.setDate(dt.getDate() - 1);
            vm.disable = disable;
            vm.dismissAll = dismissAll;
            vm.save = save;
            vm.selectedDate = null;

            vm.externalApp = options.viewData;

            function save() {
                vm.externalApp.expiryDate = vm.selectedDate;
                http.post(url.api('externalApplication/externalApplicationToken/save'), vm.externalApp)
                    .success(function (data) {
                        if (data.viewData.result === 'success') {
                            notificationService.success();
                            $uibModalInstance.close(true);
                        }
                    });
            }

            function disable() {
                return !(vm.form.$valid && vm.form.$dirty);
            }

            function dismissAll() {
                if (!vm.form.$dirty) {
                    cancel();
                    return;
                }
                notificationService.discard()
                    .then(function () {
                        cancel();
                    });
            }

            function cancel() {
                $uibModalInstance.close(false);
            }

            if (vm.externalApp.expiryDate) {
                vm.selectedDate = moment.utc(vm.externalApp.expiryDate != null ? vm.externalApp.expiryDate.replace(/-/g, ' ') : '').toDate();
            }
        }
    ]);