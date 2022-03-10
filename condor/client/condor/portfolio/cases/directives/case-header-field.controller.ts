module inprotech.portfolio.cases {
    export class CaseHeaderFieldController {
        public value: string;
        public labelId: string;
        public isFirstColumn: boolean;
        public label: string;
        public isHidden: boolean;
        public vm: CaseHeaderFieldController;

        constructor() {}

        $onInit() {
            this.vm = this;
        }
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipCaseHeaderField', {
            controllerAs: 'vm',
            bindings: {
                isFirstColumn: '<',
                labelId: '<',
                value: '<',
                screenControl: '<'
            },
            templateUrl: 'condor/portfolio/cases/directives/case-header-field.html',
            controller: CaseHeaderFieldController,
            transclude: true
        });
}