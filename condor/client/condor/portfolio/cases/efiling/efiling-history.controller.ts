'use strict'
module inprotech.portfolio.cases {
    export class CaseViewEfilingHistoryController {
        static $inject = ['$scope', '$uibModalInstance', 'localSettings', 'kendoGridBuilder', 'CaseviewEfilingService', 'options'];
        exchangeId: number;
        caseKey: number;
        packageReference: number;
        gridOptions: any;

        constructor(private $scope: any, private $uibModalInstance: any,  private localSettings: inprotech.core.LocalSettings, private kendoGridBuilder: any, private service: ICaseviewEfilingService, private options: any) {
            this.exchangeId = this.options.exchangeId;
            this.caseKey = this.options.caseKey;
            this.packageReference = this.options.packageReference;
            this.gridOptions = this.buildGridOptions();
        }

        public close = (): void => {
            this.$uibModalInstance.close();
        }

        public buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'eFilingHistory',
                autoBind: true,
                autoGenerateRowTemplate: true,
                pageable: {
                    pageSize: this.localSettings.Keys.caseView.eFiling.historyPageNumber.getLocal,
                    pageSizes: [5, 10, 20, 50, 100]
                },
                reorderable: false,
                sortable: { allowUnsort: true },
                read: (queryParams) => {
                    return this.service.getPackageHistory(this.caseKey, this.exchangeId, queryParams);
                },
                onPageSizeChanged: (pageSize) => {
                    this.localSettings.Keys.caseView.eFiling.historyPageNumber.setLocal(pageSize);
                },
                columns: this.getColumns()
            });
        }

        private getColumns = (): any => {
            return [{
                title: 'caseview.eFilingHistory.date',
                field: 'statusDateTime',
                width: '110px',
                template: '<ip-date-time model="::dataItem.statusDateTime"></ip-date-time>',
                oneTimeBinding: true
            }, {
                title: 'caseview.eFilingHistory.status',
                field: 'status',
                width: '110px',
                oneTimeBinding: true
            }, {
                title: 'caseview.eFilingHistory.description',
                field: 'statusDescription',
                oneTimeBinding: true
            }];
        }
    }

    angular.module('inprotech.portfolio.cases')
        .controller('CaseViewEfilingHistoryController', CaseViewEfilingHistoryController);

    angular.module('inprotech.portfolio.cases')
    .run(function (modalService) {
        modalService.register('ExchangeHistoryDialog', 'CaseViewEfilingHistoryController', 'condor/portfolio/cases/efiling/efiling-history.html', {
            windowClass: 'centered',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });
    });
}
