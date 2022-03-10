'use strict'
namespace inprotech.components.form {
    export class EmailTemplate {
        public recipientEmail: string;
        public recipientCopiesTo: string[];
        public subject: string;
        public body: string;
    }

    export class EmailLinkController implements ng.IController {
        public vm: EmailLinkController;
        public model: EmailTemplate;
        public email: string;
        public text: string;
        public icon: boolean;

        $onChanges(changed) {
            let m = changed.model;
            if (m && m.currentValue && !this.email) {
                this.email = this.createUri(this.model);
            }
        };

        public isValid = (): boolean => {
            return this.email != null;
        }

        createUri = (emailTemplate: EmailTemplate): string => {
            const link = [];
            if (emailTemplate.recipientCopiesTo && emailTemplate.recipientCopiesTo.length > 0) {
                link.push(`cc=${emailTemplate.recipientCopiesTo.join(';')}`);
            }
            if (emailTemplate.subject) {
                link.push(`subject=${encodeURIComponent(emailTemplate.subject)}`);
            }
            if (emailTemplate.body) {
                link.push(`body=${encodeURIComponent(emailTemplate.body)}`);
            }
            return `${'mailto:' + emailTemplate.recipientEmail}?${link.join('&')}`;
        }
    }

    class EmailLinkComponent implements ng.IComponentOptions {
        public controller: any;
        public controllerAs: string;
        public template: string;
        public bindings: any;
        public model: EmailTemplate;
        public text: string;
        public showIcon: boolean;
        constructor() {
            this.controller = EmailLinkController;
            this.controllerAs = 'vm';
            this.template = '<span ng-if="::vm.showIcon"><a ng-if="vm.isValid" href="{{vm.email}}"><span class="cpa-icon cpa-icon-envelope"></span></a></span>'
                        + '<span ng-if="::!vm.showIcon"><a ng-if="vm.isValid" href="{{vm.email}}">{{::vm.text}}</a><span ng-if="!vm.isValid">{{::vm.text}}</span></span>';
            this.bindings = {
                model: '<',
                text: '<',
                showIcon: '<'
            };
        }
    }

    angular
        .module('inprotech.components.form')
        .component('ipEmailLink', new EmailLinkComponent());
}