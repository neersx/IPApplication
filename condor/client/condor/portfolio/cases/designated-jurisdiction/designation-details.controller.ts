module inprotech.portfolio.cases {
    export class DesignationsDetailsController {
        static $inject = ['$scope', 'kendoGridBuilder', 'caseViewDesignationsService'];
        public vm: DesignationsDetailsController;
        public viewData: any;
        public showWebLink: any;
        public details: any;
        public classes: any;
        public gridOptions: any;
        public loaded = true;
        constructor(private $scope: any, private kendoGridBuilder: any, private service: ICaseViewDesignationsService) {
            this.vm = this;
        }

        $onInit() {
            if (this.viewData.caseKey) {
                this.loaded = false;
                this.service.getSummary(this.viewData.caseKey).then((data) => {
                    this.loaded = true;
                    this.details = data;
                    if (data.classes && data.classes.length > 0) {
                        this.classes = data.classes;
                    }
                });
                this.gridOptions = this.buildGridOptions();
            }
        }

        getNameLink = (nameId: string): string => {
            return '../default.aspx?nameid=' + encodeURIComponent(nameId);
        };

        private buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'caseview-designations-classes',
                navigatable: true,
                selectable: 'row',
                oneTimeBinding: true,
                autoBind: true,
                pageable: false,
                read: () => {
                    return this.classes;
                },
                autoGenerateRowTemplate: true,
                columns: [{
                    title: 'caseview.designatedJurisdiction.details.classes',
                    field: 'textClass',
                    width: '160px',
                    fixed: true
                }, {
                    title: 'caseview.designatedJurisdiction.details.language',
                    field: 'language',
                    width: '160px',
                    fixed: true
                }, {
                    title: 'caseview.designatedJurisdiction.details.goodsAndServices',
                    field: 'notes',
                    sortable: false
                }]
            });
        }
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipDesignationsDetails', {
            controllerAs: 'vm',
            bindings: {
                viewData: '<',
                showWebLink: '<'
            },
            templateUrl: 'condor/portfolio/cases/designated-jurisdiction/designation-details.html',
            controller: DesignationsDetailsController
        });
}
