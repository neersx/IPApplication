module inprotech.portfolio.cases {
    export class EventOtherDetailsController {
        event;
        public vm: EventOtherDetailsController;

        constructor() {
            this.vm = this;
        }

        public encodeLinkData = (data) => {
            return encodeURIComponent(JSON.stringify(data));
        };
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipEventOtherDetails', {
            controllerAs: 'vm',
            bindings: {
                event: '<'
            },
            templateUrl: 'condor/portfolio/cases/directives/event-other-details.html',
            controller: EventOtherDetailsController
        });
}