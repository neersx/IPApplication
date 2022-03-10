'use strict'
namespace inprotech.accounting.vat {
    export class AccountingHmrcSettingsController implements ng.IController {
        static $inject = ['VatReturnsService', 'notificationService'];
        public vm: AccountingHmrcSettingsController;
        public form: any;
        public initialData: HmrcSettingsModel = null;
        public viewData: any;
        public service: any;

        constructor(service: inprotech.accounting.vat.IVatReturnsService, private notificationService: any) {
            this.vm = this;
            this.service = service;
        };

        $onInit() {
            if (this.viewData.hmrcSettings) {
                this.initialData = new HmrcSettingsModel(this.viewData.hmrcSettings.hmrcApplicationName, this.viewData.hmrcSettings.clientId, this.viewData.hmrcSettings.redirectUri, this.viewData.hmrcSettings.clientSecret, this.viewData.hmrcSettings.isProduction);
            } else {
                this.initialData = new HmrcSettingsModel();
                this.viewData.hmrcSettings = this.initialData;
            };
        };

        hasChanged = (): Boolean => {
            return this.form && this.form.$dirty;
        };

        save = () => {
            this.service.save(this.viewData.hmrcSettings).then((response: any) => {
                if (response.data.result.status === 'success') {
                    this.notificationService.success();
                    this.form.$setPristine();
                }
            });
        };

        discard = () => {
            this.viewData.hmrcSettings.hmrcApplicationName = this.initialData.hmrcApplicationName;
            this.viewData.hmrcSettings.clientId = this.initialData.clientId;
            this.viewData.hmrcSettings.clientSecret = this.initialData.clientSecret;
            this.viewData.hmrcSettings.redirectUri = this.initialData.redirectUri;
            this.viewData.hmrcSettings.isProduction = this.initialData.isProduction;
            this.form.$setPristine();
        };
    }

    class AccountingHmrcSettingsComponent implements ng.IComponentOptions {
        public controller: any;
        public controllerAs: string;
        public templateUrl: string;
        public bindings: any;
        public viewData: any;
        constructor() {
            this.controller = AccountingHmrcSettingsController;
            this.controllerAs = 'vm';
            this.templateUrl = 'condor/accounting/vat/accounting.hmrc-settings.html';
            this.bindings = {
                viewData: '<'
            };
        }
    }

    angular
        .module('inprotech.accounting.vat')
        .component('ipHmrcSettings', new AccountingHmrcSettingsComponent());
}