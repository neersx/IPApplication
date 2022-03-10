'use strict';

namespace inprotech.portfolio.cases {
    describe('case view designated jurisdiction Details controller', function () {

        let controller: (viewData?: any, isExternal?: boolean) => DesignationsDetailsController, kendoGridBuilder, service: ICaseViewDesignationsService;

        beforeEach(function () {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(function () {
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                service = $injector.get<ICaseViewDesignationsService>('caseViewDesignationsServiceMock');

                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            });

            inject(function ($rootScope) {
                let scope = $rootScope.$new();
                controller = (viewData?: any): DesignationsDetailsController => {
                    let c = new DesignationsDetailsController(scope, kendoGridBuilder, service);
                    c.viewData = viewData || {};
                    return c;
                };
            });
        });

        describe('initialize', function () {
            it('should initialize default notes', () => {
                let c = controller({ notes: 'abc' });
                c.$onInit();
                expect(c.viewData.caseKey).toBeUndefined();
                expect(c.details).toBeUndefined();
                expect(c.gridOptions).toBeUndefined();

                expect(service.getSummary).not.toHaveBeenCalled();
            });

            it('should initialize details and fetch classes when caseKey is provided', () => {
                let summaryCall: any = service.getSummary;
                summaryCall.returnValue = {};
                let c = controller({ notes: 'abc', caseKey: 1 });
                c.$onInit();
                let o = c.gridOptions;
                expect(o.id).toBe('caseview-designations-classes');
                expect(o.columns[0].field).toBe('textClass');
                expect(o.columns[1].field).toBe('language');
                expect(o.columns[2].field).toBe('notes');
                o.read();
                expect(service.getSummary).toHaveBeenCalled();
            });
        });
    });
}