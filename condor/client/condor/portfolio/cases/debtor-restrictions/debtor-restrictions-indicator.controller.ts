module inprotech.portfolio.cases {
    export class DebtorRestrictionFlagController {
        static $inject: string[] = ['debtorRestrictionsService'];
        public debtor: number;
        public severity: string;
        public description: string;
        public vm: DebtorRestrictionFlagController;

        constructor(private service: IDebtorRestrictionsService) {
            this.vm = this;
        }

        $onInit() {
            if (!this.debtor) {
                return;
            }

            this.service.getRestrictions(this.debtor)
                .then((r: IDebtorRestriction) => {
                    this.severity = r.severity;
                    this.description = r.description;
                });
        }
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipDebtorRestrictionFlag', {
            controllerAs: 'vm',
            bindings: {
                debtor: '<'
            },
            templateUrl: 'condor/portfolio/cases/debtor-restrictions/debtor-restrictions-indicator.html',
            controller: DebtorRestrictionFlagController,
            transclude: true
        });
}