'use strict'
module inprotech.accounting.vat {
    export class AccountingViewVatReturnController {
        static $inject = ['$uibModalInstance', 'VatReturnsService', 'options', 'dateService', '$q', '$window'];
        entityNameNo: number;
        fromDate: string;
        toDate: string;
        entityName: string;
        entityTaxCode: string;
        periodKey: string;
        service: any;
        responseError: any;
        responseSuccess: any;
        selectedEntitiesNames: any;
        vatReturnDataError: any;
        vatReturnDataSuccess: any;
        vatValues: any[];
        pdfId: any;

        constructor(private $uibModalInstance: any, service: inprotech.accounting.vat.IVatReturnsService, private options: any, private dateService: any, private $q: any, public $window: ng.IWindowService) {
            this.entityNameNo = this.options.entityNameNo;
            this.fromDate = this.dateService.format(this.options.fromDate);
            this.toDate = this.dateService.format(this.options.toDate);
            this.entityName = this.options.entityName;
            this.entityTaxCode = this.options.entityTaxCode;
            this.entityNameNo = this.options.entityNameNo;
            this.selectedEntitiesNames = this.options.selectedEntitiesNames;
            this.periodKey = this.options.periodKey;
            this.pdfId = '';
            this.service = service;
            this.load();
        }

        close = (): void => {
            this.$uibModalInstance.close();
        }

        load = () => {
            let vatData = {
                vatNo: this.entityTaxCode,
                periodKey: this.periodKey,
                entityNo: this.entityNameNo,
                entityName: this.entityName,
                toDate: this.toDate,
                fromDate: this.fromDate,
                selectedEntitiesNames: this.selectedEntitiesNames
            };
            this.service.getReturn(vatData).then((response: any) => {
                this.handleResponse(response);
            });
        }

        handleResponse = (response: any) => {
            if (!_.isUndefined(response.vatResponse)) {
                this.responseSuccess = response.vatResponse;
            } else {
                this.responseError = response;
            }

            if (response.vatReturnData.status.toUpperCase() === 'OK') {
                this.vatReturnDataSuccess = response.vatReturnData.status;
                this.vatValues = _.map(response.vatReturnData.data, (n: number) => { return n.toFixed(2) });
            } else {
                this.vatReturnDataError = response.vatReturnData.error;
            }
            this.pdfId = response.pdfStorageId;
        }
        exportToPdf = () => {
            let filename = this.entityName + ' ' + this.fromDate + '-to-' + this.toDate;
            this.$window.open('accounting/vat/' + this.pdfId + '/exportToPdf/' + filename);
        }
    }

    angular.module('inprotech.accounting.vat')
        .controller('AccountingViewVatReturnController', AccountingViewVatReturnController);

    angular.module('inprotech.accounting.vat')
        .run(function(modalService) {
            modalService.register('ViewVatReturnDialog', 'AccountingViewVatReturnController', 'condor/accounting/vat/accounting.vat-fulfilled.html', {
                windowClass: 'centered',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });
}