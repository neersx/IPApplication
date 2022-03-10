module inprotech.portfolio.cases {
    export class ClassTextsController {
        static $inject = ['$scope', 'kendoGridBuilder', 'caseviewClassesService'];
        public vm: ClassTextsController;
        public viewData: any;
        public parentViewData: any;
        public classTexts: any;
        public gridOptions: any;
        public loaded = true;
        constructor(private $scope: any, private kendoGridBuilder: any, private service: ICaseviewClassesService) {
            this.vm = this;
        }

        $onInit() {
            if (this.viewData.class && this.parentViewData.caseKey) {
                this.loaded = false;
                this.service.getClassTexts(this.parentViewData.caseKey, this.getClassKey()).then((data) => {
                    this.loaded = true;
                    if (data && data.length > 0) {
                        this.classTexts = data;
                    }
                });
                this.gridOptions = this.buildGridOptions();
            }
        }

        private getClassKey = (): string => {
            if (this.parentViewData.allowSubClassWithoutItem && this.viewData.subClass) {
                return this.viewData.class + '.' + this.viewData.subClass;
            }
            return this.viewData.class;
        }

        private buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'caseview-class-texts',
                navigatable: true,
                selectable: 'row',
                oneTimeBinding: true,
                autoBind: true,
                pageable: false,
                read: () => {
                    return this.classTexts;
                },
                autoGenerateRowTemplate: true,
                columns: [{
                    title: 'caseview.classes.gstText',
                    field: 'notes',
                    sortable: false,
                    template:
                        '<span ng-if="vm.parentViewData.enableRichText === true" ng-bind-html="::dataItem.notes | html"></span><div ng-if="vm.parentViewData.enableRichText !== true" style="white-space: pre-wrap;">{{::dataItem.notes}}</div>',
                    encoded: true,
                },
                {
                    title: 'caseview.classes.language',
                    field: 'language',
                    width: '160px',
                    fixed: true
                }]
            });
        }
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipClassTexts', {
            controllerAs: 'vm',
            bindings: {
                viewData: '<',
                parentViewData: '<'
            },
            templateUrl: 'condor/portfolio/cases/classes/class-texts.html',
            controller: ClassTextsController
        });
}
