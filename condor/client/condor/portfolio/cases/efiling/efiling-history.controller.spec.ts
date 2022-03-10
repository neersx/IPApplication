'use strict';
namespace inprotech.portfolio.cases {
    describe('case view e-filing package history controller', () => {
        let controller: () => CaseViewEfilingHistoryController;
        let service: CaseViewEfilingServiceMock;
        let kendoGridBuilder: any;
        let uibModalInstance: any;
        let localSettings: any;
        let store: any;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector([
                    'inprotech.mocks',
                    'inprotech.mocks.core'
                ]);

                service = $injector.get <ICaseviewEfilingService> (
                    'CaseViewEfilingServiceMock'
                );
                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                uibModalInstance = $injector.get('ModalInstanceMock');
                store = $injector.get('storeMock');
                localSettings = new inprotech.core.LocalSettings(store);
            });

            inject(($rootScope) => {
                let scope = $rootScope.$new();
                let options = {exchangeId: 1, caseKey: -1}
                controller = () => {
                    let c = new CaseViewEfilingHistoryController(
                        scope,
                        uibModalInstance,
                        localSettings,
                        kendoGridBuilder,
                        service,
                        options
                    );

                    return c;
                };
            });
        });

        describe('initialize', () => {
            it('should initialise grid options', () => {
                let c = controller();
                expect(c.gridOptions).toBeDefined();
                expect(c.gridOptions.pageable.pageSize).toBe(localSettings.Keys.caseView.eFiling.historyPageNumber.getLocal);
                expect(c.gridOptions.sortable).toEqual({
                    allowUnsort: true
                });
		        expect(c.gridOptions.reorderable).toBe(false);
            });
        });

        describe('fetching data', () => {
            it('should call the service with correct parameters', () => {
                let c = controller();
                c.gridOptions.read();
                expect(service.getPackageHistory).toHaveBeenCalled();
            });
        });
    });
}