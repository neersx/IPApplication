'use strict';
namespace inprotech.portfolio.cases {
    export class CaseTextHistoryController {
        static $inject = ['$scope', '$uibModalInstance', 'kendoGridBuilder', 'caseViewCaseTextsService', 'options'];

        public viewdata: any;
        public gridOptions: any;
        public currentItem: any;
        public showDiffierence: any;

        constructor(private $scope: any, private $uibModalInstance: any, private kendoGridBuilder: any, private caseViewCaseTextsService: ICaseViewCaseTextsService, private options: any) {
            this.gridOptions = this.buildGridOptions();
            this.showDiffierence = true;
        }

        public buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'caseViewCaseTextHistory',
                autoBind: true,
                pageable: false,
                navigatable: true,
                sortable: true,
                scrollable: true,
                reoderable: false,
                autoGenerateRowTemplate: true,
                read: () => {
                    return this.caseViewCaseTextsService.getTextHistory(this.options.dataItem.caseKey, this.options.dataItem.typeKey, this.options.dataItem.languageKey).then((data) => {
                        this.viewdata = data;
                        if (this.viewdata.history) {
                            this.viewdata.history[this.viewdata.history.length - 1].previous = this.viewdata.history[this.viewdata.history.length - 1].text;
                            for (let i = this.viewdata.history.length - 2; i >= 0; i--) {
                                this.viewdata.history[i].previous = this.viewdata.history[i + 1].text;
                            }
                        }
                        return this.viewdata.history;
                    })
                },
                columns: this.getColumns()
            });
        }

        private getColumns = (): any => {
            return [{
                title: 'caseview.caseTexts.modified',
                field: 'dateModified',
                width: '160px',
                fixed: true,
                template: '<ip-date-time model="::dataItem.dateModified"></ip-date-time>'
            }, {
                title: 'caseview.caseTexts.text',
                field: 'text',
                fixed: true,
                sortable: false,
                headerTemplate: '<div class="col-md-8" translate="caseview.caseTexts.text" style="height:18px;"></div><div class="input-wrap switch col-md-4" style="height:18px;"><input id="showDiffierenceSwitch" type="checkbox" ng-model="vm.showDiffierence"><label for="showDiffierenceSwitch" translate="caseview.caseTexts.showDiffierence"></label></div>',
                template: '<div ng-if="vm.showDiffierence" in-comparison text="{ left: dataItem.previous, right: dataItem.text}"></div>' +
                    '<div ng-if= "!vm.showDiffierence">{{dataItem.text}}</div>'
            }];
        }

        public close = (): void => {
            this.$uibModalInstance.close();
        }
    }

    angular.module('inprotech.portfolio.cases')
        .controller('CaseTextHistoryController', CaseTextHistoryController);
}

