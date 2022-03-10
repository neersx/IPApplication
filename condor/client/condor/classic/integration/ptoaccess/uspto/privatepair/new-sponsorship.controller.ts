'use strict';
namespace Inprotech.Integration.PtoAccess {
    export class NewUsptoPrivatePairSponsorshipController {
        static $inject = ['$uibModalInstance', 'hotkeys', 'notificationService', 'modalService', 'sponsorshipService', 'options'];
        public vm: NewUsptoPrivatePairSponsorshipController;
        public form: ng.IFormController;
        public isUpdateMode = false;
        public isSaving = false;
        public errors = {};
        public customerNumbers = '';
        private customerNumberForUpdateComparison: string[];
        public sponsorship = {
            id: null,
            name: null,
            email: null,
            password: null,
            authenticatorKey: null,
            customerNumbers: null,
            serviceId: null
        };
        serviceInfo: string;

        constructor(private $uibModalInstance, private hotkeys, private notificationService, private modalService, private sponsorshipService, private options) {
            this.vm = this;
            if (this.options.data && this.options.data.item) {
                this.isUpdateMode = true;
                this.sponsorship.id = this.options.data.item.id;
                this.sponsorship.name = this.options.data.item.name;
                this.sponsorship.email = this.options.data.item.email;
                this.sponsorship.password = '            ';
                this.sponsorship.authenticatorKey = '                  ';
                this.sponsorship.customerNumbers = this.options.data.item.customerNumbers;
                this.sponsorship.serviceId = this.options.data.item.serviceId;
                this.customerNumberForUpdateComparison = this.sponsorship.customerNumbers.split(',');

                this.serviceInfo = this.options.data.clientId + ' | ' + this.sponsorship.serviceId;
            }
            this.customerNumbers = this.options.data.customerNumbers.replace(this.sponsorship.customerNumbers, '');
        }

        disable = () => {
            let isValid = this.form.$dirty && this.form.$valid;
            if (this.isUpdateMode && isValid) {
                return !(this.sponsorship.password || this.sponsorship.authenticatorKey || this.hasCustomersNumberChanged());
            }
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

        private hasCustomersNumberChanged = (): boolean => {
            let cNumbers: string[] = this.sponsorship.customerNumbers.trim().split(',').filter(x => x);
            if (this.customerNumberForUpdateComparison.length === cNumbers.length) {
                return this.customerNumberForUpdateComparison.filter(x => cNumbers.indexOf(x) === -1).length > 0;
            }
            return true;
        }

        save = () => {
            if (this.isSaving) { return; }
            this.errors = {};
            if (this.form && this.form.$validate) {
                this.form.$validate();
            }
            if (!this.form.$valid) {
                return;
            }
            this.isSaving = true;
            let model = this.getTrimOutput(this.sponsorship);
            this.sponsorshipService.addOrUpdate(model, this.isUpdateMode)
                .then(this.afterSave)
                .finally(() => {
                    this.isSaving = false;
                });
        }

        getTrimOutput = (input) => {
            let output = {};
            Object.keys(input).map(k =>
                (typeof input[k] === 'string' || input[k] instanceof String) ?
                    output[k] = input[k].trim() : output[k] = input[k]);

            return output;
        }

        afterSave = (response) => {
            if (response.data.isSuccess === true) {
                this.$uibModalInstance.close(true);
                this.notificationService.success();
            } else {
                this.notificationService.alert({
                    title: 'modal.unableToComplete',
                    message: (response.data.key) ? 'dataDownload.uspto.new.errors.'
                        + response.data.key : 'dataDownload.uspto.new.errors.default',
                    messageParams: {
                        number: response.data.error
                    },
                });
            }
        }

        initShortcuts = () => {
            this.hotkeys.add({
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: function () {
                    if (!this.disable() && this.modalService.canOpen('NewUsptoSponsorship')) {
                        this.save();
                    }
                }
            });
            this.hotkeys.add({
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: function () {
                    if (this.modalService.canOpen('NewUsptoSponsorship')) {
                        this.dismissAll();
                    }
                }
            });
        }
    }

    angular.module('Inprotech.Integration.PtoAccess').controller('newUsptoPrivatePairSponsorshipController', NewUsptoPrivatePairSponsorshipController)
}