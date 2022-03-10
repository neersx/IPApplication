'use strict'
namespace inprotech.portfolio.cases {
    export class CaseViewEfilingController implements ng.IController {
        static $inject = ['$scope', 'kendoGridBuilder', 'localSettings', 'CaseviewEfilingService', 'modalService', 'bus'];
        public vm: CaseViewEfilingController;
        public gridOptions: any;
        public viewData: any;
        public topic: any;
        subscription: any;
        constructor(private $scope: any, private kendoGridBuilder: any, private localSettings: inprotech.core.LocalSettings, private service: ICaseviewEfilingService, private modalService: any, private bus: any) {
            this.vm = this;
        }

        $onInit() {
            this.gridOptions = this.buildGridOptions();
            this.subscription = this.bus.channel('policingCompleted').subscribe(this.reloadData);
        }

        public reloadData = () => {
            this.gridOptions.search();
        };

        $onDestroy() {
            this.subscription.unsubscribe();
        }

        public buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'caseview-efiling',
                autoBind: true,
                pageable: {
                    pageSize: this.localSettings.Keys.caseView.eFiling.pageNumber.getLocal,
                    pageSizes: [5, 10, 20, 50]
                },
                navigatable: true,
                selectOnNavigate: true,
                autoGenerateRowTemplate: true,
                topicItemNumberKey: this.topic.key,
                sortable: {
                    allowUnsort: true
                },
                read: (queryParams) => {
                    return this.service.getPackages(this.viewData.caseKey, queryParams);
                },
                onPageSizeChanged: (pageSize) => {
                    this.localSettings.Keys.caseView.eFiling.pageNumber.setLocal(pageSize);
                },
                columns: this.getColumns(),
                columnSelection: {
                    localSetting: this.getColumnSelectionLocalSetting()
                },
                showExpandIfCondition: true,
                detailTemplate: '<ip-case-view-efiling-package-files exchange-id="::dataItem.exchangeId" package-sequence="::dataItem.packageSequence" case-key="vm.viewData.caseKey"><ip-case-view-efiling-package-files/>'
            });
        }

        private getColumns = (): any => {
            return [{
                title: 'caseview.eFiling.packageType',
                field: 'packageType',
                oneTimeBinding: true,
                menu: true
            }, {
                title: 'caseview.eFiling.packageReference',
                field: 'packageReference',
                oneTimeBinding: true,
                menu: true
            }, {
                width: 20,
                template: '<span><a class="cpa-icon text-grey-highlight cpa-icon-history" ng-click="vm.openHistory(dataItem.exchangeId, dataItem.packageReference)" uib-tooltip="{{::\'caseview.eFiling.viewStatusHistory\' | translate }}" tooltip-class="tooltip-info"></a></span>'
            }, {
                title: 'caseview.eFiling.currentStatus',
                field: 'currentStatus',
                template: '<ip-hover-help data-content="{{::dataItem.currentStatusDescription}}"><span>{{::dataItem.currentStatus}}</span></ip-hover-help>',
                menu: true
            }, {
                title: 'caseview.eFiling.nextEventDue',
                field: 'nextEventDue',
                oneTimeBinding: true,
                menu: true
            }, {
                title: 'caseview.eFiling.date',
                field: 'lastStatusChange',
                template: '<ip-date-time model="::dataItem.lastStatusChange"></ip-date-time>',
                menu: true
            }, {
                title: 'caseview.eFiling.user',
                field: 'userName',
                oneTimeBinding: true,
                menu: true,
                hidden: true
            }, {
                title: 'caseview.eFiling.server',
                field: 'server',
                oneTimeBinding: true,
                menu: true,
                hidden: true
            }];
        }

        private getColumnSelectionLocalSetting = () => {
            return this.localSettings.Keys.caseView.eFiling.columnsSelection;
        }

        public openHistory = (exchangeId: number, packageReference: string): any => {
            this.modalService.openModal({
                id: 'ExchangeHistoryDialog',
                controllerAs: 'vm',
                exchangeId: exchangeId,
                caseKey: this.viewData.caseKey,
                packageReference: packageReference
            })
        };
    }

    class CaseViewEfilingComponent implements ng.IComponentOptions {
        public controller: any;
        public controllerAs: string;
        public templateUrl: string;
        public bindings: any;
        public viewData: any;
        constructor() {
            this.controller = CaseViewEfilingController;
            this.controllerAs = 'vm';
            this.templateUrl = 'condor/portfolio/cases/efiling/efiling.html';
            this.bindings = {
                viewData: '<',
                topic: '<'
            }
        }
    }
    angular.module('inprotech.portfolio.cases')
        .component('ipCaseViewEfiling', new CaseViewEfilingComponent());
}