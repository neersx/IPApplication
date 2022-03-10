'use strict';

namespace inprotech.portfolio.cases {
    describe('case view case texts controller', function () {

        let controller, kendoGridBuilder, localSettings: inprotech.core.LocalSettings, store, service: ICaseViewCaseTextsService;

        beforeEach(function () {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(function () {
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                service = $injector.get<ICaseViewCaseTextsService>('caseViewCaseTextsServiceMock');
                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                store = $injector.get('storeMock');
                localSettings = new inprotech.core.LocalSettings(store);
            });

            inject(function ($rootScope) {
                let scope = $rootScope.$new();
                controller = (viewData, filters, topic) => {
                    let c = new CaseViewCaseTextsController(scope, kendoGridBuilder, service, localSettings, null);
                    c.viewData = viewData || {};
                    c.keepSpecHistory = true;
                    c.topic = topic || {}
                    c.filters = filters;
                    c.$onInit();
                    return c;
                };
            });
        });

        describe('initialize Grid', function () {
            it('should initialise grid options', () => {
                let c = controller();
                expect(c.gridOptions).toBeDefined();
            });

            it('should have correct column order', () => {
                let c = controller();
                expect(c.gridOptions.columns.length).toBe(4);
                expect(c.gridOptions.columns[0].field).toBe('type');
                expect(c.gridOptions.columns[1].field).toBe('hasHistory');
                expect(c.gridOptions.columns[2].field).toBe('notes');
                expect(c.gridOptions.columns[3].field).toBe('language');
            });

            it('should have correct name, page number and column selection for unfiltered text topic', () => {
                let c = controller();
                let o = c.gridOptions;

                expect(o.id).toBe('caseViewCaseTexts');
                expect(o.pageable.pageSize).toBe(localSettings.Keys.caseView.texts.pageNumber.getLocal);
                expect(o.pageable.pageSizes).toEqual([5, 10, 20, 50]);
                expect(o.columnSelection.localSetting).toBe(localSettings.Keys.caseView.texts.columnsSelection);
            });

            it('should have correct name, page number and column selection for filtered text topic', () => {
                let c = controller({}, { textTypeKey: 'CL' }, { contextKey: '_ContextualGrid' });
                let o = c.gridOptions;

                expect(o.id).toBe('caseViewCaseTexts_ContextualGrid');
                expect(o.pageable.pageSize).toBe(localSettings.Keys.caseView.texts.pageNumber.getLocalwithSuffix('CL'));
                expect(o.pageable.pageSizes).toEqual([5, 10, 20, 50]);
                expect(o.columnSelection.localSetting).toBe(localSettings.Keys.caseView.texts.columnsSelection);
            });
        });
    });
}