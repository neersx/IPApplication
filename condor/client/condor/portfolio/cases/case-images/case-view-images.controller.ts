'use strict';
namespace inprotech.portfolio.cases {
    export class CaseViewImagesController implements ng.IController {
        static $inject = ['$scope', 'CaseViewImagesService'];
        vm: CaseViewImagesController;
        viewData: any;
        topic: any;
        images: any;
        imagesCount: number;
        showMore: Boolean;
        showAll: Boolean;
        imageWidth: any;
        imageNumberToDisplay = 0;

        constructor(private readonly $scope: any, private readonly service: ICaseViewImagesService) {
            this.vm = this;
        }

        $onInit() {
            this.service.getCaseImages(this.viewData.caseKey).then((data) => {
                this.images = data;
                this.imagesCount = data.length;
                if (this.topic.setCount && this.imagesCount > 0) {
                    this.topic.setCount.emit(this.imagesCount);
                }
            });
        }
    }

    class CaseViewImagesComponent implements ng.IComponentOptions {
        controller: any;
        controllerAs: string;
        templateUrl: string;
        bindings: any;
        viewData: any;
        constructor() {
            this.controller = CaseViewImagesController;
            this.controllerAs = 'vm';
            this.templateUrl = 'condor/portfolio/cases/case-images/case-view-images.html';
            this.bindings = {
                viewData: '<',
                topic: '<'
            }
        }
    }

    export class IpCaseViewImagesWidthAwareDirective implements ng.IDirective {
        restrict: string;
        transclude: false;
        scope: {
            maxViewable: '='
        }

        constructor() {
            this.restrict = 'A';
        }

        link(scope, element: any): any {
            scope.$watch(() => {
                return element[0].clientWidth;
            }, (newVal: any) => {
                scope.maxViewable = Math.floor(Number(newVal) / 212);
            });
        }
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipCaseViewImages', new CaseViewImagesComponent())

    angular.module('inprotech.portfolio.cases')
        .directive('ipCaseViewImagesWidthAware', () => new IpCaseViewImagesWidthAwareDirective());
}