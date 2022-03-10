module inprotech.portfolio.cases {
    declare var moment: any;
    export class DueDateController {
        static $inject: string[] = ['$scope'];
        public vm: DueDateController;
        public isOverdue: boolean;
        public isToday: boolean;
        public date: string;

        constructor(private $scope: ng.IScope) { }

        $onInit() {
            this.vm = this;
            this.$scope.$watch('vm.date', () => {
                this.isToday = moment().isSame(moment(this.date), 'day');
                this.isOverdue = moment().isSameOrAfter(moment(this.date), 'day');
            })
        }
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipDueDate', {
            templateUrl: 'condor/portfolio/cases/due-date.html',
            controllerAs: 'vm',
            bindings: {
                date: '<',
                showToolTip: '@'
            },
            controller: DueDateController
        });
}