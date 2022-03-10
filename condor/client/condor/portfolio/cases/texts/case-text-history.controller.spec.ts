'use strict';

namespace inprotech.portfolio.cases {
    describe('case view case texts controller', function () {

        let controller, kendoGridBuilder, service, modalInstance;

        beforeEach(function () {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(function () {
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                service = $injector.get<ICaseViewCaseTextsService>('caseViewCaseTextsServiceMock');
                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                modalInstance = $injector.get('ModalInstanceMock');
            });

            inject(function ($rootScope) {
                let scope = $rootScope.$new();
                let options = {
                    dataItem: {
                        caseKey: 1001,
                        typeKey: 'GS',
                        language: 'EN'
                    }
                }
                service.getTextHistory.returnValue = {
                    irn: 1001,
                    textClass: null,
                    textDescription: 'Goods/Services',
                    language: 'Bahasa',
                    type: 'G',
                    typeKey: null,
                    history: [{ dateModified: '2018-07-11T16:56:58.66', text: 'imp1' },
                    { dateModified: '2018-07-11T16:56:49.567', text: 'imp2' }]
                };

                controller = () => {
                    let c = new CaseTextHistoryController(scope, modalInstance, kendoGridBuilder, service, options);
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
                expect(c.gridOptions.columns.length).toBe(2);
                expect(c.gridOptions.columns[0].field).toBe('dateModified');
                expect(c.gridOptions.columns[1].field).toBe('text');
            });

            it('should close modal after click', () => {
                let c = controller();
                c.close();
                expect(modalInstance.close).toHaveBeenCalled();
            });

            it('should have query service with correct information', () => {
                let c = controller();
                let o = c.gridOptions;
                o.read();

                expect(service.getTextHistory).toHaveBeenCalledWith(
                    1001, 'GS', undefined);

                expect(c.viewdata).toEqual({ irn: 1001, textClass: null, textDescription: 'Goods/Services', language: 'Bahasa', type: 'G', typeKey: null, history: [Object({ dateModified: '2018-07-11T16:56:58.66', text: 'imp1', previous: 'imp2' }), Object({ dateModified: '2018-07-11T16:56:49.567', text: 'imp2', previous: 'imp2' })] });
            });
        });
    });
}