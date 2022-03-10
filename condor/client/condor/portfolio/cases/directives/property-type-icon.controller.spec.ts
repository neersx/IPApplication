namespace inprotech.portfolio.cases {
    describe('inprotech.portfolio.cases.propertyTypeIcon', () => {
        'use strict';

        let c: PropertyTypeIconController;
        let controller: (viewData?: any) => PropertyTypeIconController, scope: any,
            caseViewService;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

                caseViewService = $injector.get('CaseViewServiceMock');
            });
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService) => {
            scope = $rootScope.$new();
            controller = function (viewData?) {
                viewData = angular.extend({
                    imageKey: 789
                }, viewData);

                let cont = new PropertyTypeIconController(scope, caseViewService);
                angular.extend(cont, viewData);
                return cont;
            };
        }));

        describe('initialise view', () => {
            it('should setup a watch on imageKey', () => {
                spyOn(scope, '$watch');
                c = controller();
                c.$onInit();
                expect(scope.$watch).toHaveBeenCalledWith('vm.imageKey', jasmine.any(Function));
            });
        });

        describe('load image', () => {
            it('should load the property type image', () => {
                scope.$watch = jasmine.createSpy('watchSpy');
                caseViewService.getPropertyTypeIcon.returnValue = {};
                c = controller({
                    isThumbnail: false
                });
                c.$onInit();
                let loadImage = scope.$watch.calls.first().args[1];
                expect(loadImage).toBeDefined();

                loadImage();
                expect(caseViewService.getPropertyTypeIcon).toHaveBeenCalledWith(789);
            });

            it('should set the property type image data', () => {
                scope.$watch = jasmine.createSpy('watchSpy');
                c = controller({
                    isThumbnail: false
                });
                c.$onInit();
                let returnValue = {
                    image: '¯\_(ツ)_/¯'
                }
                caseViewService.getPropertyTypeIcon.returnValue = returnValue;
                let loadImage = scope.$watch.calls.first().args[1];
                loadImage();

                expect(c.image).toEqual(returnValue.image);
            });
        });
    });
}
