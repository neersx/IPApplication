'use strict';
namespace inprotech.portfolio.cases {
    describe('case view e-filing controller', () => {
        let controller: () => CaseViewEfilingController;
        let service: CaseViewEfilingServiceMock,
            kendoGridBuilder,
            localSettings: inprotech.core.LocalSettings,
            store,
            modalService, promiseMock, bus;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector([
                    'inprotech.mocks',
                    'inprotech.mocks.core'
                ]);

                service = $injector.get<ICaseviewEfilingService>(
                    'CaseViewEfilingServiceMock'
                );
                store = $injector.get('storeMock');
                localSettings = new inprotech.core.LocalSettings(store);
                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                modalService = $injector.get('modalServiceMock');
                promiseMock = $injector.get('promiseMock');
                bus = $injector.get('BusMock');
            });

            inject($rootScope => {
                let scope = $rootScope.$new();
                controller = () => {
                    let c = new CaseViewEfilingController(
                        scope,
                        kendoGridBuilder,
                        localSettings,
                        service,
                        modalService,
                        bus
                    );
                    c.viewData = {
                        caseKey: 123
                    };
                    c.topic = { key: 'efiling' };
                    return c;
                };
            });
        });

        describe('initialize', function () {
            let c: CaseViewEfilingController, g: any, validateColumn: (column: string) => void, validateHiddenColumn: (column: string) => void;
            let expectedColumns: string[] = ['packageType', 'packageReference', 'statusHistoryIcon', 'currentStatus', 'nextEventDue', 'lastStatusChange', 'userName', 'server'];
            let validate = (index: number, column: string, hidden: boolean) => {
                expect(g.columns[index].field).toBe(column);
                expect(g.columns[index].menu).toBe(true);
                expect(g.columns[index].hidden || false).toBe(hidden);
            };
            validateColumn = (column: string) => {
                validate(expectedColumns.indexOf(column), column, false);
            };
            validateHiddenColumn = (column: string) => {
                validate(expectedColumns.indexOf(column), column, true);
            };

            it('should initialise correct grid options', () => {
                c = controller();
                c.$onInit();
                g = c.gridOptions;

                expect(g).toBeDefined();
                expect(g.id).toBe('caseview-efiling');
                expect(g.pageable.pageSizes).toEqual([5, 10, 20, 50]);
                expect(store.local.get).toHaveBeenCalled();
                expect(g.columnSelection.localSetting).toBe(localSettings.Keys.caseView.eFiling.columnsSelection);
                expect(g.pageable.pageSize).toBe(localSettings.Keys.caseView.eFiling.pageNumber.getLocal);
                validateColumn('packageType');
                validateColumn('packageReference');
                validateColumn('currentStatus');
                validateColumn('nextEventDue');
                validateColumn('lastStatusChange');
                validateHiddenColumn('userName');
                validateHiddenColumn('server');
                expect(_.where(g.columns, { menu: true }).length).toBe(7);
                expect(_.where(g.columns, { hidden: true }).length).toBe(2);
                expect(_.where(g.columns, { hidden: true })[0]['field']).toBe('userName');
                expect(_.where(g.columns, { hidden: true })[1]['field']).toBe('server');
                g.read();
                expect(service.getPackages).toHaveBeenCalled();
            });
        });

        describe('clicking on history icon', () => {
            let c: CaseViewEfilingController;
            beforeEach(() => {
                c = controller();
                c.$onInit();
                c.gridOptions.read();
                modalService.openModal = promiseMock.createSpy();
            });
            it('should open up history dialog', () => {
                c.openHistory(111, '1234/A-00');
                expect(modalService.openModal).toHaveBeenCalledWith({
                    id: 'ExchangeHistoryDialog',
                    controllerAs: 'vm',
                    exchangeId: 111,
                    caseKey: 123,
                    packageReference: '1234/A-00'
                });
            });
        });
    });
}