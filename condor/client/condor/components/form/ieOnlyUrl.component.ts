module inprotech.components.form {
    export class IeOnlyUrlController {
        static $inject = ['featureDetection', 'modalService'];

        public vm: IeOnlyUrlController;
        public url: string;
        public text: string;
        public isIe = false;
        public inproVersion16 = false;
        constructor(private featureDetection: inprotech.core.IFeatureDetection, private modalService) {
        }

        $onInit() {
            this.isIe = this.featureDetection.isIe();
            this.inproVersion16 = this.featureDetection.hasRelease16();
            this.vm = this;
        }

        showIeRequired = () => {
            this.modalService.openModal({
                id: 'ieRequired',
                controllerAs: 'vm',
                url: this.featureDetection.getAbsoluteUrl(this.url)
            });
        }

        linkText = () => {
            return this.text;
        }
    }

    angular.module('inprotech.components.form')
        .component('ipIeOnlyUrl', {
            controllerAs: 'vm',
            transclude: true,
            bindings: {
                url: '<',
                text: '<'
            },
            template: '<a ng-if="::!vm.isIe && !vm.inproVersion16" ng-click="vm.showIeRequired()" class="text"><span>{{ vm.linkText() }}</span><span ng-transclude></span></a><a ng-if="::vm.isIe || vm.inproVersion16" href="{{vm.url}}" class="text" target="_blank"><span>{{ vm.linkText() }}</span><span ng-transclude></span></a>',
            controller: IeOnlyUrlController
        });
}