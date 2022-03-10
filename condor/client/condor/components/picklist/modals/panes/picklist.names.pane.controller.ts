'use strict'
module inprotech.components.picklist {
    export class PicklistNamesPaneController {
        static $inject = ['$scope', 'PicklistNamesPaneService', 'dateService'];
        public vm: PicklistNamesPaneController;
        public nameId: number;
        public nameDetailData: any;
        private loadDataDebounce: Function;

        constructor(private $scope: any, private namesPaneService: IPicklistNamesPaneService, private dateService: any) {
            this.vm = this;
            this.loadDataDebounce = _.debounce(this.loadData, 300);
        }

        $onInit() {
            this.$scope.$watch('vm.nameId', () => {
                this.loadDataDebounce();
            });
        }

        loadData = () => {
            if (this.nameId) {
                this.namesPaneService.getName(this.nameId)
                    .then((nameDetails) => {
                        this.nameDetailData = nameDetails;
                        if (this.nameDetailData.startDate) {
                            this.nameDetailData.startDate = this.dateService.format(this.nameDetailData.startDate);
                        }
                        if (this.nameDetailData.dateCeased) {
                            this.nameDetailData.ceasedDateInPast = new Date() > new Date(this.nameDetailData.dateCeased);
                            this.nameDetailData.dateCeased = this.dateService.format(this.nameDetailData.dateCeased);
                        }
                    }
                );
            }
        };
    }

    class PicklistNamesPaneComponent implements ng.IComponentOptions {
        public controller: any;
        public controllerAs: string;
        public templateUrl: string;
        public bindings: any;
        public selectedItem: any;
        constructor() {
            this.controller = PicklistNamesPaneController;
            this.controllerAs = 'vm';
            this.templateUrl = 'condor/components/picklist/modals/panes/picklist.names.pane.html';
            this.bindings = {
                nameId: '<'
            };
        }
    }

    angular.module('inprotech.components.picklist')
        .component('ipPicklistNamesPane', new PicklistNamesPaneComponent());
}