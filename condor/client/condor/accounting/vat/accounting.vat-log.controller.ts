'use strict'
module inprotech.accounting.vat {
    export class AccountingVatLogController {
        static $inject = ['$scope', '$uibModalInstance', 'VatReturnsService', 'options', 'kendoGridBuilder', 'dateService', 'localSettings'];
        entityNameNo: number;
        fromDate: string;
        toDate: string;
        entityName: string;
        entityTaxCode: string;
        selectedEntitiesNames: string;
        periodKey: string;
        service: any;
        public gridOptions: any;

        constructor(private $scope: any, private $uibModalInstance: any, service: inprotech.accounting.vat.IVatReturnsService, private options: any, private kendoGridBuilder: any, private dateService: any, private localSettings: inprotech.core.LocalSettings) {
            this.fromDate = this.dateService.format(this.options.fromDate);
            this.toDate = this.dateService.format(this.options.toDate);
            this.entityName = this.options.entityName;
            this.entityTaxCode = this.options.entityTaxCode;
            this.entityNameNo = this.options.entityNameNo;
            this.selectedEntitiesNames = this.options.selectedEntitiesNames;
            this.periodKey = this.options.periodKey;
            this.service = service;
            this.gridOptions = this.buildGridOptions();
        }

        public buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'accounting-vat-logs',
                autoBind: true,
                autoGenerateRowTemplate: true,
                sortable: {
                    allowUnsort: true
                },
                read: () => {
                    return this.service.getLogs(this.entityTaxCode, this.periodKey);
                },
                columns: this.getColumns(),
                columnSelection: {
                    localSetting: this.getColumnSelectionLocalSetting()
                }
            });
        };

        private getColumns = (): any => {
            return [{
                    title: 'accounting.vatLog.date',
                    width: '30%',
                    fixed: true,
                    field: 'date',
                    template: '<ip-date-time model="::dataItem.date"></ip-date-time>',
                    oneTimeBinding: true
                },
                {
                    title: 'accounting.vatLog.message',
                    fixed: true,
                    field: 'data',
                    sortable: false,
                    template: '<span>{{ \'accounting.vatLog.code\' | translate }}{{ dataItem.message.code }} </br> {{ \'accounting.vatLog.logMessage\' | translate }}{{ dataItem.message.message }}</span>' +
                            '<ul><li ng-repeat="e in dataItem.message.errors" >{{ e.code }}: {{ e.message }} {{ e.path }}</li></ul>',
                    oneTimeBinding: true
                }
            ];
        };

        private getColumnSelectionLocalSetting = () => {
            return this.localSettings.Keys.accounting.vatLogs.columnsSelection;
        };

        close = (): void => {
            this.$uibModalInstance.close();
        };
    }

    angular.module('inprotech.accounting.vat')
        .controller('AccountingVatLogController', AccountingVatLogController);

    angular.module('inprotech.accounting.vat')
        .run(function(modalService) {
            modalService.register('VatErrorLogDialog', 'AccountingVatLogController', 'condor/accounting/vat/accounting.vat-log.html', {
                windowClass: 'centered',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });
}