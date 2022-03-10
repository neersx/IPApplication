module inprotech.components.form {
    export class HostedUrlController {

        public vm: HostedUrlController;
        public case: string;
        public action: string;
        public key: string;
        public description: string;
        public programId: string;
        public isHosted = false;
        public hostProgramId: string;
        public actionData: any;
        constructor(private $rootScope: any, private dngWindowParentMessagingService: any) { }

        $onInit() {
            this.isHosted = this.$rootScope.isHosted;
            this.hostProgramId = this.$rootScope.hostedProgramId;
            this.vm = this;

        }

        buildLink() {
            if (this.action && this.key) {
                this.actionData = { action: this.action, type: 'N', key: this.key, program: this.programId || this.hostProgramId };
            }
        };

        postMessage() {
            if (this.isHosted && !this.actionData) {
                this.buildLink();
            }
            this.dngWindowParentMessagingService.postNavigationMessage(this.actionData);
        }
    }

    angular.module('inprotech.components.form')
        .component('ipHostedUrl', {
            controllerAs: 'vm',
            transclude: true,
            bindings: {
                action: '<',
                key: '<',
                description: '<',
                programId: '<'
            },
            template: '<a ng-if="vm.isHosted && vm.action && vm.key" ng-click="vm.postMessage()">{{::vm.description}}</a><span ng-if="!vm.isHosted" ng-transclude></span>',
            controller: HostedUrlController
        });
}