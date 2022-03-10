'use strict'
namespace inprotech.portfolio.cases {

    export class CaseViewCaseTextsController implements ng.IController {
        static $inject = ['$scope', 'kendoGridBuilder', 'caseViewCaseTextsService', 'localSettings', 'modalService'];
        public gridOptions: any;
        public viewData: any;
        public enableRichText: any;
        public keepSpecHistory: any;
        public filters: any;
        public topic: any;
        public vm: CaseViewCaseTextsController;
        public content: any;
        textTypeKeys: string;

        constructor(private $scope: any, private kendoGridBuilder: any, private service: ICaseViewCaseTextsService, private localSettings: inprotech.core.LocalSettings, private modalService) {
            this.vm = this;
        }

        $onInit() {
            this.textTypeKeys = (this.filters || { textTypeKey: '' }).textTypeKey || '';
            this.gridOptions = this.buildGridOptions();
        }

        public buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'caseViewCaseTexts' + (this.topic.contextKey || ''),
                autoBind: true,
                pageable: {
                    pageSize: this.topicSetting().pageNumber.getLocalwithSuffix(this.textTypeKeys),
                    pageSizes: [5, 10, 20, 50]
                },
                onPageSizeChanged: (pageSize) => {
                    this.topicSetting().pageNumber.setLocal(pageSize, this.textTypeKeys);
                },
                navigatable: true,
                sortable: true,
                reoderable: false,
                resizable: true,
                selectOnNavigate: true,
                autoGenerateRowTemplate: true,
                read: (queryParams) => {
                    let textTypeKeys = this.textTypeKeys.split(',');
                    return this.service.getTexts(this.viewData.caseKey, textTypeKeys, queryParams);
                },
                columns: this.getColumns(),
                topicItemNumberKey: this.topic.key,
                columnSelection: {
                    localSetting: this.topicSetting().columnsSelection
                }
            });
        }

        public openTextHistoryModal = (dataItem) => {
            let modalOptions: IModalOptions = {
                id: 'CaseTextHistory',
                controllerAs: 'vm',
                dataItem: angular.extend(dataItem, { caseKey: this.viewData.caseKey }),
                allItems: this.gridOptions.data(),
                callbackFn: this.gridOptions.search
            };
            this.modalService.openModal(modalOptions);
        }

        private topicSetting = (): any => this.localSettings.Keys.caseView.texts;

        private getColumns = (): any => {
            let columns = [{
                title: 'caseview.caseTexts.type',
                field: 'type',
                width: '190px',
                fixed: true,
                sortable: false,
                template: '<span>{{dataItem.type}}</span>'
            }, {
                title: 'caseview.caseTexts.notes',
                field: 'notes',
                template: '<span ng-if="vm.enableRichText === true" ng-bind-html="::dataItem.notes | html"></span><div ng-if="vm.enableRichText !== true" style="white-space: pre-wrap;">{{::dataItem.notes}}</div>'
            }, {
                title: 'caseview.caseTexts.language',
                field: 'language',
                width: '200px',
                fixed: true
            }];

            if (this.keepSpecHistory === true) {
                columns.splice(1, 0, {
                    title: '',
                    field: 'hasHistory',
                    width: '40px',
                    fixed: true,
                    sortable: false,
                    template: '<a ng-click="vm.openTextHistoryModal(dataItem)" ng-if="dataItem.hasHistory === true" class="cpa-icon text-grey-highlight cpa-icon-history" ip-tooltip="{{::\'caseview.caseTexts.notesText\' | translate }}" ></a>'
                });

            }
            return columns;
        }
    }

    class CaseViewCaseTextsComponent implements ng.IComponentOptions {

        public controller: any;
        public controllerAs: string;
        public templateUrl: string;
        public bindings: any;
        public viewData: any;
        public enableRichText: any;
        public keepSpecHistory: any;

        constructor() {
            this.controller = CaseViewCaseTextsController;
            this.controllerAs = 'vm';
            this.templateUrl = 'condor/portfolio/cases/texts/case-texts.html';
            this.bindings = {
                viewData: '<',
                enableRichText: '<',
                keepSpecHistory: '<',
                filters: '<',
                topic: '<'
            }
        }
    }
    angular.module('inprotech.portfolio.cases')
        .component('ipCaseViewCaseTexts', new CaseViewCaseTextsComponent());
}