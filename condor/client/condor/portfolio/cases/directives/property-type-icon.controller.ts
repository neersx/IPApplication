module inprotech.portfolio.cases {
    export class PropertyTypeIconController {
        static $inject: string[] = ['$scope', 'CaseViewService'];
        public vm: PropertyTypeIconController;
        public imageKey: number;
        public image: any;

        constructor(private $scope: ng.IScope, private caseViewService: ICaseViewService) {}

        $onInit() {
            this.vm = this;
            this.$scope.$watch('vm.imageKey', () => {
                this.loadImage();
            });
        }

        private loadImage() {
            this.caseViewService.getPropertyTypeIcon(this.imageKey)
                .then((data) => {
                    this.image = data.image;
                });
        }
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipPropertyTypeIcon', {
            controllerAs: 'vm',
            bindings: {
                imageKey: '<'
            },
            template: '<span><img ng-src="data:image/PNG;base64,{{vm.image}}"></img></span>',
            controller: PropertyTypeIconController
        });
}
