'use strict'
namespace inprotech.portfolio.cases {

    export class CaseViewDesignationsController implements ng.IController {
        static $inject = ['$rootScope', '$scope', 'kendoGridBuilder', 'localSettings', 'caseViewDesignationsService'];
        public gridOptions: any;
        public viewData: any;
        public ippAvailability: any;
        public showWebLink: boolean;
        public vm: CaseViewDesignationsController;
        public eventType: any;
        public isExternal: boolean;
        public topic: any;
        constructor($rootScope, public $scope: any, public kendoGridBuilder: any, private localSettings: inprotech.core.LocalSettings, private service: ICaseViewDesignationsService) {
            this.vm = this;
            this.isExternal = $rootScope.appContext.user.isExternal;
        }

        $onInit() {
            this.gridOptions = this.buildGridOptions();
        }

        private buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'caseview-designations',
                navigatable: true,
                pageable: {
                    pageSize: this.localSettings.Keys.caseView.designatedJurisdiction.pageNumber.getLocal,
                    pageSizes: [10, 20, 50, 100, 250]
                },
                selectable: 'row',
                scrollable: true,
                resizable: true,
                oneTimeBinding: true,
                autoBind: true,
                topicItemNumberKey: this.topic.key,
                read: (queryParams) => {
                    return this.service.getCaseViewDesignatedJurisdictions(this.viewData.caseKey, queryParams);
                },
                readFilterMetadata: (column) => {
                    return this.service.getColumnFilterData(this.viewData.caseKey, column, this.gridOptions.getFiltersExcept(column));
                },
                filterOptions: {
                    keepFiltersAfterRead: true,
                    sendExplicitValues: true
                },
                onPageSizeChanged: (pageSize) => {
                    this.localSettings.Keys.caseView.designatedJurisdiction.pageNumber.setLocal(pageSize);
                },
                autoGenerateRowTemplate: true,
                columns: this.getColumns(),
                columnSelection: {
                    localSetting: this.localSettings.Keys.caseView.designatedJurisdiction.columnsSelection
                },
                showExpandIfCondition: 'dataItem.notes || dataItem.caseKey',
                detailTemplate: '<ip-designations-details view-data="::dataItem" show-web-link="vm.showWebLink"></ip-designations-details>'
            });
        }

        private getColumns = () => {
            let columns: any = [{
                width: '40px',
                fixed: true,
                sortable: false,
                menu: false,
                template: '<span ng-if="::dataItem.notes" class="cpa-icon text-grey-highlight cpa-icon-file-o" ip-tooltip="{{::\'caseview.designatedJurisdiction.eventNoteHover\' | translate }}" ></span>'
            }, {
                title: 'caseview.designatedJurisdiction.jurisdiction',
                field: 'jurisdiction',
                filterable: true,
                width: '160px',
                menu: true
            }, {
                title: 'caseview.designatedJurisdiction.designatedStatus',
                field: 'designatedStatus',
                filterable: true,
                width: '160px',
                menu: true
            }, {
                title: 'caseview.designatedJurisdiction.officialNumber',
                field: 'officialNumber',
                width: '100px',
                menu: true
            }, {
                title: 'caseview.designatedJurisdiction.caseStatus',
                field: 'caseStatus',
                width: '160px',
                filterable: true,
                menu: true
            }];

            if (this.isExternal) {
                columns.push({
                    title: 'caseview.designatedJurisdiction.clientReference',
                    field: 'clientReference',
                    width: '160px',
                    menu: true
                })
            }

            columns.push({
                title: this.internalReferenceTitle(),
                field: 'internalReference',
                menu: true,
                width: '160px',
                template: '<a ng-if="::dataItem.canView && dataItem.caseKey" ui-sref="caseview({id: {{dataItem.caseKey}}})" target="_blank">{{dataItem.internalReference}}</a>' +
                    '<span ng-if="::!dataItem.canView" class="cpa-icon text-grey-highlight cpa-icon-ban" ip-tooltip="{{::\'caseview.designatedJurisdiction.accessDenied\' | translate }}"></span>'
            }, {
                    title: 'caseview.designatedJurisdiction.classes',
                    field: 'classes',
                    menu: true,
                    width: '120px',
                    hidden: true
                }, {
                    title: 'caseview.designatedJurisdiction.priorityDate',
                    field: 'priorityDate',
                    menu: true,
                    width: '120px',
                    hidden: true,
                    template: '<ip-date model="::dataItem.priorityDate"></ip-date>'
                }, {
                    title: 'caseview.designatedJurisdiction.isExtensionState',
                    field: 'isExtensionState',
                    menu: true,
                    hidden: true,
                    width: '80px',
                    template: '<ip-checkbox ng-model="::dataItem.isExtensionState" disabled><ip-checkbox>'
                });

            if (!this.isExternal) {
                columns.push({
                    title: 'caseview.designatedJurisdiction.instructorReference',
                    field: 'instructorReference',
                    menu: true,
                    width: '120px',
                    hidden: true
                }, {
                        title: 'caseview.designatedJurisdiction.agentReference',
                        field: 'agentReference',
                        menu: true,
                        width: '100px',
                        hidden: true
                    });
            }

            if (this.ippAvailability.file.isEnabled && this.ippAvailability.file.hasViewAccess) {
                columns.unshift({
                    width: '40px',
                    fixed: true,
                    sortable: false,
                    field: 'isFiled',
                    menu: false,
                    template: '<ip-file-instruct-link case-key="::dataItem.caseKey" is-filed="::dataItem.isFiled" can-access="::dataItem.canViewInFile"></ip-file-instruct-link>'
                });
            }

            return columns;
        }

        private internalReferenceTitle = (): string => {
            if (this.isExternal) {
                return 'caseview.designatedJurisdiction.ourReference';
            }
            return 'caseview.designatedJurisdiction.internalReference';
        }
    }
    class CaseViewDesignationsComponent implements ng.IComponentOptions {

        public controller: any;
        public controllerAs: string;
        public templateUrl: string;
        public bindings: any;
        constructor() {
            this.controller = CaseViewDesignationsController;
            this.controllerAs = 'vm';
            this.templateUrl = 'condor/portfolio/cases/designated-jurisdiction/designations.html';
            this.bindings = {
                viewData: '<',
                topic: '<',
                ippAvailability: '<',
                showWebLink: '<'
            }
        }
    }
    angular.module('inprotech.portfolio.cases')
        .component('ipCaseViewDesignations', new CaseViewDesignationsComponent());

}