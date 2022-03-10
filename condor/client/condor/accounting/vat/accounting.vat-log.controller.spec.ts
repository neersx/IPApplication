namespace inprotech.accounting.vat {
    describe('should show logs', () => {
        let controller: () => AccountingVatLogController,
            service: any,
            uibModalInstance: any,
            promiseMock: any,
            dateService: any;

        beforeEach(() => {
            angular.mock.module('inprotech.accounting.vat');
            inject(($rootScope) => {
                let $injector: ng.auto.IInjectorService = angular.injector([
                    'inprotech.mocks',
                    'inprotech.mocks.core'
                ]);
                let scope = $rootScope.$new();
                let kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                let store = $injector.get('storeMock');
                let localSettings = new inprotech.core.LocalSettings(store);
                dateService = $injector.get('dateServiceMock');
                uibModalInstance = $injector.get('ModalInstanceMock');
                promiseMock = $injector.get < any > ('promiseMock');
                service = $injector.get('VatReturnsServiceMock');
                let options = {
                    entityNameNo: 1,
                    fromDate: new Date(),
                    toDate: new Date(),
                    entityName: 'entity',
                    entityTaxCode: 'taxcode',
                    periodKey: '18A2',
                    selectedEntitiesNames: 'entity, entity1.'
                }
                controller = () => {
                    let c = new AccountingVatLogController(
                        scope,
                        uibModalInstance,
                        service,
                        options,
                        kendoGridBuilder,
                        dateService,
                        localSettings
                    );
                    return c;
                };
            });
        });

        describe('initialize', () => {
            it('should initialise the log modal', () => {
                service.getLogs = promiseMock.createSpy([{
                    date: new Date(),
                    message: {
                        code: 'bad request',
                        message: 'this is a bad request'
                    }
                }]);
                dateService.format = promiseMock.createSpy(new Date());

                let c = controller();
                expect(c.fromDate).toBeDefined();
                expect(c.toDate).toBeDefined();
                expect(c.entityName).toBeDefined();
                expect(c.entityNameNo).toBeDefined();
                expect(c.entityTaxCode).toBeDefined();
                expect(c.selectedEntitiesNames).toBeDefined();
                let grid = c.gridOptions;
                expect(grid).toBeDefined();
                expect(grid.columns.length).toBe(2);
                expect(grid.columns[0].title).toBe('accounting.vatLog.date');
                expect(grid.columns[1].title).toBe('accounting.vatLog.message');
            });
        });
    });
}