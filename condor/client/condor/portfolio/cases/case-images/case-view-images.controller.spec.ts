'use strict';

namespace inprotech.portfolio.cases {
    describe('case view images controller', function() {

        let controller: (viewData: any) => CaseViewImagesController, service: ICaseViewImagesService, promiseMock: any, scope: ng.IScope, compileDirective, directiveScope, eventEmitterMock: any;

        beforeEach(function() {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(function() {
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                service = $injector.get<ICaseViewImagesService>('CaseViewImagesServiceMock');
                promiseMock = $injector.get<any>('promiseMock');
                eventEmitterMock = {
                    emit: (n: number) => { }
                };
            });

            inject(function($compile, $rootScope) {
                scope = $rootScope.$new();
                directiveScope = $rootScope.$new();
                controller = (viewData?: any): CaseViewImagesController => {
                    let c = new CaseViewImagesController(scope, service);
                    c.viewData = viewData || {};
                    c.topic = {
                        key: 'images',
                        setCount: eventEmitterMock
                    };
                    return c;
                };

                compileDirective = function(directiveMarkup) {
                    let defaultMarkup = '<div ip-case-view-images-width-aware style="width:1000px;"></div>';
                    $compile(directiveMarkup || defaultMarkup)(directiveScope);
                    directiveScope.$digest();
                };
            });
        });

        describe('initialize', function() {
            it('has default maxImage allowed value', function() {
                compileDirective();
                expect(directiveScope).toBeDefined();
                expect(directiveScope.maxViewable).toBeDefined();
            });
            it('should initialize case view images', () => {
                let c = controller({
                    caseKey: 123
                });
                service.getCaseImages = promiseMock.createSpy([{
                    caseKey: 1,
                    imageKey: 1,
                    imageDescription: 'image description a',
                    imageType: 'image type a'
                },
                {
                    caseKey: 2,
                    imageKey: 2,
                    imageDescription: 'image description b',
                    imageType: 'image type b'
                },
                {
                    caseKey: 3,
                    imageKey: 3,
                    imageDescription: 'image long description Test, image long description Test, image long description Test, image long description Test, image long description Test,',
                    imageType: 'image type c'
                }
                ]);
                spyOn(eventEmitterMock, 'emit');
                c.$onInit();

                expect(c.viewData.caseKey).toBeDefined();
                expect(c.viewData.caseKey).toEqual(123);
                expect(c.images).toBeDefined();
                expect(c.imagesCount).toBeDefined();
                expect(c.imagesCount).toEqual(3);
                expect(service.getCaseImages).toHaveBeenCalled();
                expect(eventEmitterMock.emit).toHaveBeenCalledWith(3);
            });
        });
    });
}