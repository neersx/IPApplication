module inprotech.portfolio.cases {
    'use strict';
    export class CaseSummaryController {
        static $inject: string[] = ['$scope'];
        hasImage: boolean;
        showWebLink: boolean;
        public isExternal: boolean;
        public hasScreenControl: boolean;
        public screenControl: any;
        public viewData: any;
        public vm: CaseSummaryController;
        constructor(private $scope: any, private bus: any) {
            this.vm = this;
            this.vm.hasImage = this.$scope.withImage;
            this.vm.viewData = this.$scope.viewData;
            this.vm.screenControl = this.$scope.screenControl;
            this.vm.isExternal = this.$scope.isExternal;
            this.vm.showWebLink = this.$scope.showWebLink;
            this.vm.hasScreenControl = this.$scope.hasScreenControl || false;
        }
    }
    angular.module('inprotech.portfolio.cases')
        .controller('CaseSummaryController', CaseSummaryController)
        .directive('ipCaseviewSummary', function (bus) {
            'use strict';
            return {
                restrict: 'E',
                scope: {
                    viewData: '<',
                    screenControl: '<',
                    withImage: '<',
                    isExternal: '<',
                    showWebLink: '<',
                    hasScreenControl: '<'
                },
                bus,
                controller: 'CaseSummaryController',
                controllerAs: 'vm',
                bindToController: {
                    topic: '='
                },
                template: '<div ng-include="\'condor/portfolio/cases/directives/summary-with-image.html\'" ng-if="::vm.hasImage"></div><div ng-include="\'condor/portfolio/cases/directives/summary-no-image.html\'" ng-if="::!vm.hasImage"></div>'
            };
        });
}