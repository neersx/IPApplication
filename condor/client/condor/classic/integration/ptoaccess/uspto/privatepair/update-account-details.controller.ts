'use strict';
namespace Inprotech.Integration.PtoAccess {
    export class UpdateUsptoAccountDetailsController {
        static $inject = ['$uibModalInstance', 'hotkeys', 'notificationService', 'sponsorshipService', 'options'];

        public form: ng.IFormController;
        public isSaving = false;
        public vm: UpdateUsptoAccountDetailsController;
        public data = {
            queueUrl: null,
            queueId: null,
            queueSecret: null
        };
        public serviceInfo: string;
        constructor(private $uibModalInstance, private hotkeys, private notificationService, private sponsorshipService, private options) {
            this.vm = this;
            this.serviceInfo = this.options.data.clientId
        }

        disable = () => {
            let isValid = this.form.$dirty && this.form.$valid;
            return !isValid;
        }

        cancel = () => {
            this.$uibModalInstance.close(false);
        }

        dismissAll = () => {
            if (!this.form.$dirty) {
                this.cancel();
                return;
            }
            this.notificationService.discard()
                .then(() => {
                    this.cancel();
                });
        }

        save = () => {
            if (this.isSaving) { return; }
            if (this.form && this.form.$validate) {
                this.form.$validate();
            }
            if (!this.form.$valid) {
                return;
            }
            this.notificationService.confirm({
                message: 'dataDownload.uspto.updateAccountDetails.saveConfirm'
            }).then(() => {
                this.isSaving = true;
                let model = this.data;
                this.sponsorshipService.updateAccountSettings(model)
                    .then(this.afterSave, () => {
                        this.notificationService.alert({ message: 'dataDownload.uspto.updateAccountDetails.errors.default' });
                    })
                    .finally(() => {
                        this.isSaving = false;
                    });
            });

        }

        afterSave = (response) => {
            if (response.data.isSuccess === true) {
                this.$uibModalInstance.close(true);
                this.notificationService.success();
            } else {
                this.notificationService.alert({
                    title: 'modal.unableToComplete',
                    message: (response.data.key) ? 'dataDownload.uspto.updateAccountDetails.errors.' + response.data.key : 'dataDownload.uspto.updateAccountDetails.errors.default'
                });
            }
        }

        initShortcuts = () => {
            this.hotkeys.add({
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: function () {
                    if (!this.disable() && this.modalService.canOpen('updateUsptoAccountDetails')) {
                        this.save();
                    }
                }
            });
            this.hotkeys.add({
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: function () {
                    if (this.modalService.canOpen('updateUsptoAccountDetails')) {
                        this.dismissAll();
                    }
                }
            });
        }
    }

    angular.module('Inprotech.Integration.PtoAccess').controller('updateUsptoAccountDetailsController', UpdateUsptoAccountDetailsController)
}