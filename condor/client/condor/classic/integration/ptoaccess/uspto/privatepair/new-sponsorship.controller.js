angular.module('Inprotech.Integration.PtoAccess')
    .controller('newUsptoPrivatePairSponsorshipController', ['$uibModalInstance', 'hotkeys', 'notificationService', 'modalService', 'sponsorshipService', 'options',

        function ($uibModalInstance, hotkeys, notificationService, modalService, sponsorshipService, options) {
            'use strict';
            var vm = this;

            vm.isUpdateMode = false;
            vm.form = {};
            vm.sponsorship = {
                id: null,
                name: null,
                email: null,
                password: null,
                authenticatorKey: null,
                customerNumbers: null,
                serviceId: null
            };

            if (options.item) {
                vm.isUpdateMode = true;
                vm.sponsorship.id = options.item.id;
                vm.sponsorship.name = options.item.name;
                vm.sponsorship.email = options.item.email;
                vm.sponsorship.password = options.item.password;
                vm.sponsorship.authenticatorKey = options.item.authenticatorKey;
                vm.sponsorship.customerNumbers = options.item.customerNumbers;
                vm.sponsorship.serviceId = options.item.serviceId;
            }

            vm.disable = disable;
            vm.dismissAll = dismissAll;
            vm.save = save;
            vm.afterSave = afterSave;
            vm.initShortcuts = initShortcuts;
            vm._isSaving = false;

            function disable() {
                return !(vm.form.maintenance.$dirty && vm.form.maintenance.$valid);
            }

            function cancel() {
                $uibModalInstance.close(false);
            }

            function dismissAll() {
                if (!vm.form.maintenance.$dirty) {
                    cancel();
                    return;
                }
                notificationService.discard()
                    .then(function () {
                        cancel();
                    });
            }

            function save() {
                if (vm._isSaving) return;
                vm.errors = {};
                if (vm.form.maintenance && vm.form.maintenance.$validate) {
                    vm.form.maintenance.$validate();
                }
                if (vm.form.maintenance.$invalid) {
                    return;
                }
                vm._isSaving = true;

                var fd = new FormData();
                Object.keys(vm.sponsorship).forEach(function (key) {
                    fd.append(key, vm.sponsorship[key]);
                });

                sponsorshipService.addOrUpdate(vm.sponsorship, vm.isUpdateMode)
                    .then(afterSave)
                    .finally(function () {
                        vm._isSaving = false;
                    });
            }

            function afterSave(response) {
                if (response.data.result.viewData.isSuccess == true) {
                    $uibModalInstance.close(true);
                    notificationService.success();
                } else {
                    notificationService.alert({
                        title: 'modal.unableToComplete',
                        message: (response.data.result.viewData.error) ? 'dataDownload.uspto.new.errors.' + response.data.result.viewData.error : 'dataDownload.uspto.new.errors.default'
                    });
                }
            }

            function initShortcuts() {
                hotkeys.add({
                    combo: 'alt+shift+s',
                    description: 'shortcuts.save',
                    callback: function () {
                        if (!disable() && modalService.canOpen('NewUsptoSponsorship')) {
                            vm.save();
                        }
                    }
                });
                hotkeys.add({
                    combo: 'alt+shift+z',
                    description: 'shortcuts.close',
                    callback: function () {
                        if (modalService.canOpen('NewUsptoSponsorship')) {
                            vm.dismissAll();
                        }
                    }
                });
            }
        }
    ]);