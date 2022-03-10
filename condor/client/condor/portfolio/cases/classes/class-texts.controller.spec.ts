'use strict';

namespace inprotech.portfolio.cases {
    describe('case view class texts controller', function () {

        let controller: (viewData?: any, parentViewData?: any) => ClassTextsController, kendoGridBuilder, service: ICaseviewClassesService;

        beforeEach(function () {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(function () {
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                service = $injector.get<ICaseviewClassesService>('caseviewClassesServiceMock');

                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            });

            inject(function ($rootScope) {
                let scope = $rootScope.$new();
                controller = (viewData?: any, parentViewData?: any): ClassTextsController => {
                    let c = new ClassTextsController(scope, kendoGridBuilder, service);
                    c.viewData = viewData || {};
                    c.parentViewData = parentViewData || {};
                    return c;
                };
            });
        });

        describe('initialize', function () {
            it('should not call the class Texts if case Key is not passed', () => {
                let c = controller({ class: '01' });
                c.$onInit();
                expect(c.classTexts).toBeUndefined();
                expect(c.gridOptions).toBeUndefined();
            });

            it('should not call the class Texts if class Key is not passed', () => {
                let c = controller({}, { caseKey: 1 });
                c.$onInit();
                expect(c.classTexts).toBeUndefined();
                expect(c.gridOptions).toBeUndefined();
            });

            it('should initialize details and fetch classes when caseKey is provided', () => {
                let summaryCall: any = service.getClassTexts;
                summaryCall.returnValue = {};
                let c = controller({ class: '01' }, { caseKey: 1 });
                c.$onInit();
                let o = c.gridOptions;
                expect(o.id).toBe('caseview-class-texts');
                expect(o.columns[0].field).toBe('notes');
                expect(o.columns[1].field).toBe('language');
                o.read();
            });
        });
    });
}