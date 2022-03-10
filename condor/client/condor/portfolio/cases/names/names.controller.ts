'use strict'
namespace inprotech.portfolio.cases {

    export class CaseviewNamesController implements ng.IController {
        static $inject = ['$scope', 'kendoGridBuilder', 'caseviewNamesService', 'localSettings', 'displayableFields'];

        public vm: CaseviewNamesController;
        public gridOptions: any;
        public viewData: any;
        public topic: any;
        public screenCriteriaKey: any;
        public isExternal: boolean;
        public showWebLink: boolean;
        showBillPercentage: boolean;
        nameTypeKeys: string;

        constructor(private $scope: any, private kendoGridBuilder: any, private service: ICaseviewNamesService, private localSettings: inprotech.core.LocalSettings, private displayableFields: DisplayableNameTypeFieldsHelper) {
            this.vm = this;
        }

        $onInit() {
            this.nameTypeKeys = (this.topic.filters || {
                nameTypeKey: ''
            }).nameTypeKey || '';
            this.showBillPercentage = this.viewData.hasBillPercentageDisplayed && _.any(this.nameTypeKeys.split(','), (nameTypeKey) =>
                _.contains(this.viewData.hasBillPercentageDisplayed, nameTypeKey)
            );
            this.gridOptions = this.buildGridOptions();
        }

        public buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'caseViewNames' + (this.topic.contextKey || 'DefaultGrid'),
                autoBind: true,
                oneTimeBinding: true,
                pageable: {
                    pageSize: this.localSettings.Keys.caseView.names.pageNumber.getLocalwithSuffix(this.nameTypeKeys)
                },
                navigatable: true,
                selectOnNavigate: true,
                autoGenerateRowTemplate: true,
                topicItemNumberKey: this.topic.key,
                showExpandIfCondition: 'dataItem.canView && vm.hasDetails(dataItem)',
                detailTemplate: '<ip-name-details details="::dataItem" case-id="::vm.viewData.caseKey"></ip-name-details>',
                read: (queryParams) => {
                    let nameTypeKeyString = this.nameTypeKeys.split(',');
                    return this.service.getNames(this.viewData.caseKey, nameTypeKeyString, this.screenCriteriaKey, queryParams);
                },
                onPageSizeChanged: (pageSize) => {
                    this.localSettings.Keys.caseView.names.pageNumber.setLocal(pageSize, this.nameTypeKeys);
                },
                columns: this.getColumns(this.viewData.displayNameVariants || false),
                columnSelection: {
                    localSetting: this.localSettings.Keys.caseView.names.columnsSelection,
                    localSettingSuffix: this.nameTypeKeys
                }
            });
        }

        public hasDetails = (dataItem): boolean => {
            let f = NameTypeFieldFlags;
            return this.displayableFields.shouldDisplay(dataItem.displayFlags, [f.address, f.telecom, f.assignDate, f.dateCommenced, f.dateCeased, f.billPercentage, f.remarks, f.nationality]);
        }

        private getColumns = (displayNameVariants: boolean): any => {
            let nameVariantColumnInsertIndex = 3;

            let columns = [{
                title: 'caseview.names.type',
                field: 'type'
            }, {
                width: 15,
                field: 'shouldCheckRestrictions',
                sortable: false,
                fixed: true,
                template: '<ip-debtor-restriction-flag debtor="::dataItem.id" ng-if="::dataItem.shouldCheckRestrictions" style="margin-left: 5px"></ip-debtor-restriction-flag>'
            }, {
                title: 'caseview.names.name',
                field: 'name',
                template: '<div ng-if="::dataItem.canView"><ip-ie-only-url ng-if="::dataItem.id && vm.showWebLink" data-url="vm.encodeLinkData(dataItem.id)" data-text="::dataItem.nameAndCode" style="display:inline-block;"></ip-ie-only-url><span ng-if="!vm.showWebLink">{{::dataItem.nameAndCode}}</span><ip-inheritance-icon inheritance-level="InheritedOrDerived" data-ng-if="::dataItem.isInherited && !vm.isExternal" style="padding-left: 5px"></ip-inheritance-icon></div>'
                    + '<span ng-if="::!dataItem.canView" class="cpa-icon text-grey-highlight cpa-icon-ban" ip-tooltip="{{::\'common.accessDenied.nameAccessDenied\' | translate }}"></span>'
            }, {
                title: 'caseview.names.attention',
                field: 'attention',
                template: '<div ng-if="::dataItem.canView"><ip-ie-only-url ng-if="::dataItem.attention && vm.showWebLink" data-url="vm.encodeLinkData(dataItem.attentionId)" data-text="::dataItem.attention" style="display:inline-block;"></ip-ie-only-url><span ng-if="!vm.showWebLink">{{::dataItem.attention}}</span><ip-inheritance-icon inheritance-level="InheritedOrDerived" data-ng-if="::dataItem.isAttentionDerived && !vm.isExternal" style="padding-left: 5px"></ip-inheritance-icon></div>'
                    + '<span ng-if="::!dataItem.canView" class="cpa-icon text-grey-highlight cpa-icon-ban" ip-tooltip="{{::\'common.accessDenied.nameAccessDenied\' | translate }}"></span>'
            }, {
                title: 'caseview.names.reference',
                field: 'reference'
            }];

            if (this.isExternal) {
                columns.splice(1, 1);
                nameVariantColumnInsertIndex -= 1;
            }
            if (this.showBillPercentage) {
                columns.push({
                    title: 'caseview.names.billPercentage',
                    field: 'billingPercentage'
                });
            }
            if (displayNameVariants) {
                columns.splice(nameVariantColumnInsertIndex, 0, {
                    title: 'caseview.names.nameVariant',
                    field: 'nameVariant'
                });
            }
            return columns;
        }

        encodeLinkData = (data) => {
            return 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({
                nameKey: data
            }));
        };
    }

    class CaseviewNamesComponent implements ng.IComponentOptions {

        public controller: any;
        public controllerAs: string;
        public templateUrl: string;
        public bindings: any;
        public viewData: any;
        constructor() {
            this.controller = CaseviewNamesController;
            this.controllerAs = 'vm';
            this.templateUrl = 'condor/portfolio/cases/names/names.html';
            this.bindings = {
                viewData: '<',
                topic: '<',
                screenCriteriaKey: '<',
                isExternal: '<',
                showWebLink: '<'
            }
        }
    }

    angular.module('inprotech.portfolio.cases').component('ipCaseviewNames', new CaseviewNamesComponent());
}