'use strict'
module inprotech.accounting.vat {
    export class AccountingVatSubmitterController {
        static $inject = ['$uibModalInstance', 'VatReturnsService', 'options', 'dateService', '$q', '$window'];
        entityNameNo: number;
        fromDate: string;
        toDate: string;
        entityName: string;
        entityTaxCode: string;
        periodKey: string;
        selectedEntitiesNames: string;
        gridOptions: any;
        service: any;
        vatValues: [any, any, any, any, any, any, any, any, any];
        canProceed: Boolean;
        responseError: any;
        responseSuccess: any;
        pdfId: string;

        constructor(private $uibModalInstance: any, service: inprotech.accounting.vat.IVatReturnsService, private options: any, private dateService: any, private $q: any, public $window: ng.IWindowService) {
            this.entityNameNo = this.options.entityNameNo;
            this.fromDate = this.dateService.format(this.options.fromDate);
            this.toDate = this.dateService.format(this.options.toDate);
            this.entityName = this.options.entityName;
            this.entityTaxCode = this.options.entityTaxCode;
            this.entityNameNo = this.options.entityNameNo;
            this.selectedEntitiesNames = this.options.selectedEntitiesNames;
            this.periodKey = this.options.periodKey;
            this.service = service;
            this.canProceed = false;
            this.populateVAT();
            this.pdfId = '';
            this.vatValues = ['', '', '', '', '', '', '', '', ''];
        }

        public close = (): void => {
            this.$uibModalInstance.close(this.responseSuccess);
        }

        public export = (): void => {
            let filename = (this.selectedEntitiesNames === '' ? this.entityName : 'VAT Group') + ' ' + this.fromDate + '-to-' + this.toDate;
            this.$window.open('accounting/vat/' + this.pdfId + '/exportToPdf/' + filename);
        }

        public vatBox3 = (): any => {
            if (_.isFinite(Number(this.vatValues[0])) && _.isFinite(Number(this.vatValues[1]))) {
                this.vatValues[2] = (Number(this.vatValues[0]) + Number(this.vatValues[1])).toFixed(2);
            } else {
                this.vatValues[2] = 'accounting.vatSubmitter.notCalculate';
            }
        }

        public vatBox5 = (): any => {
            if (_.isFinite(Number(this.vatValues[2])) && _.isFinite(Number(this.vatValues[3]))) {
                this.vatValues[4] = (Math.abs(Number(this.vatValues[2]) - Number(this.vatValues[3]))).toFixed(2);
            } else {
                this.vatValues[4] = 'accounting.vatSubmitter.notCalculate';
            }
        }

        submit = () => {
            this.canProceed = false;
            let vatData = {
                vatValues: this.vatValues,
                vatNo: this.entityTaxCode,
                entityName: this.entityName,
                periodKey: this.periodKey,
                entityNo: this.entityNameNo,
                toDate: this.toDate,
                fromDate: this.fromDate,
                selectedEntitiesNames: this.selectedEntitiesNames
            };
            this.service.submitVatData(vatData).then((response: any) => {
                this.handleSubmissionResponse(response);
            });
        }

        handleSubmissionResponse = (response: any) => {
            if (response.data.processingDate && response.data.formBundleNumber) {
                this.responseSuccess = response.data;
            } else {
                this.responseError = response.data;
            }
            this.pdfId = response.pdfStorageId;
        }

        private populateVAT = () => {
            let result = [1, 2, 4, 6, 7, 8, 9].reduce((accumulator, nextId) => {
                return accumulator.then(() => {
                    return this.getVatData(nextId);
                });
            }, this.$q.resolve());

            result.then((e) => {
                this.canProceed = _.every(this.vatValues, (v: any) => {
                    return _.isFinite(v);
                });
            });
        }

        private getVatData = (vatBoxNumber: any) => {
            return this.service.getVatData(vatBoxNumber, this.entityNameNo, this.fromDate, this.toDate)
                .then((data: any) => {
                    this.vatValues[vatBoxNumber - 1] = _.isNumber(data.value) ? Number(data.value).toFixed(2) : 'accounting.vatSubmitter.noDocItem';
                    if (vatBoxNumber === 2) {
                        this.vatBox3();
                    }
                    if (vatBoxNumber === 4) {
                        this.vatBox5();
                    }
                });
        }
    }

    angular.module('inprotech.accounting.vat')
        .controller('AccountingVatSubmitterController', AccountingVatSubmitterController);

    angular.module('inprotech.accounting.vat')
        .run(function(modalService) {
            modalService.register('VatSubmitterDialog', 'AccountingVatSubmitterController', 'condor/accounting/vat/accounting.vat-submitter.html', {
                windowClass: 'centered',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });
}