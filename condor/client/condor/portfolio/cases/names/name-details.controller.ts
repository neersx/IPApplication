module inprotech.portfolio.cases {
       export class NameDetailsController {
        static $inject = ['displayableFields', 'caseviewNamesService'];
        public vm: NameDetailsController;
        public details: any;
        public email: inprotech.components.form.EmailTemplate;
        public caseId: number;
        constructor(private displayableFields: DisplayableNameTypeFieldsHelper, private service: ICaseviewNamesService) {
            this.vm = this;
        }

        $onInit() {
            this.vm = this;
            if (this.details.email) {
                this.service.getFirstEmailTemplate(this.caseId, this.details.typeId, this.details.sequence)
                    .then((emailTemplate: inprotech.components.form.EmailTemplate) => {
                        this.email = {
                            recipientEmail: this.details.email,
                            recipientCopiesTo: emailTemplate.recipientCopiesTo,
                            subject: emailTemplate.subject,
                            body: emailTemplate.body
                        };
                    });
            }
        }

        public show = (flagName: string): boolean => {
            let f = this.displayableFields.mapFlag(flagName);
            return this.displayableFields.shouldDisplay(this.details.displayFlags, [f]);
        }
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipNameDetails', {
            controllerAs: 'vm',
            bindings: {
                caseId: '<',
                details: '<'
            },
            templateUrl: 'condor/portfolio/cases/names/name-details.html',
            controller: NameDetailsController
        });
}