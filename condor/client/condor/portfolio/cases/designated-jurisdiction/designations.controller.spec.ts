'use strict';

namespace inprotech.portfolio.cases {
    describe('case view designated jurisdiction controller', function () {

        let controller: (viewData?: any, isExternal?: boolean, ippAvailability?: IppAvailability) => CaseViewDesignationsController, kendoGridBuilder, localSettings: inprotech.core.LocalSettings, store, service: ICaseViewDesignationsService;

        beforeEach(function () {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(function () {
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                service = $injector.get<ICaseViewDesignationsService>('caseViewDesignationsServiceMock');

                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                store = $injector.get('storeMock');
                localSettings = new inprotech.core.LocalSettings(store);
            });

            inject(function ($rootScope) {
                let scope = $rootScope.$new();
                controller = (viewData?: any, isExternal?: boolean, ippAvailability?: IppAvailability): CaseViewDesignationsController => {
                    $rootScope.appContext = {
                        user: {
                            isExternal: isExternal
                        }
                    }
                    let c = new CaseViewDesignationsController($rootScope, scope, kendoGridBuilder, localSettings, service);
                    c.viewData = viewData || {};
                    c.ippAvailability = ippAvailability || { file: {} };
                    c.topic = { key: 'designatedJurisdiction' };
                    return c;
                };
            });
        });

        describe('initialize', function () {
            let initController, validateColumn: (column: string) => void, validateHiddenColumn: (column: string) => void, c: CaseViewDesignationsController, o: any, expectedColumnOrder: string[];
            beforeEach(() => {
                initController = (viewData?: any, isExternal?: boolean, ippAvailability?: any) => {
                    c = controller(viewData, isExternal, ippAvailability);
                    c.$onInit();
                    o = c.gridOptions;
                    if (isExternal) {
                        expectedColumnOrder = ['note', 'jurisdiction', 'designatedStatus', 'officialNumber', 'caseStatus', 'clientReference', 'internalReference', 'classes', 'priorityDate', 'isExtensionState'];
                    } else if (ippAvailability) {
                        expectedColumnOrder = ['isFiled', 'note', 'jurisdiction', 'designatedStatus', 'officialNumber', 'caseStatus', 'internalReference', 'classes', 'priorityDate', 'isExtensionState', 'instructorReference', 'agentReference'];
                    } else {
                        expectedColumnOrder = ['note', 'jurisdiction', 'designatedStatus', 'officialNumber', 'caseStatus', 'internalReference', 'classes', 'priorityDate', 'isExtensionState', 'instructorReference', 'agentReference'];
                    }
                };
                let validate = (index: number, column: string, hidden: boolean) => {
                    expect(o.columns[index].field).toBe(column);
                    expect(o.columns[index].menu).toBe(true);
                    expect(o.columns[index].hidden || false).toBe(hidden);
                };
                validateColumn = (column: string) => {
                    validate(expectedColumnOrder.indexOf(column), column, false);
                };
                validateHiddenColumn = (column: string) => {
                    validate(expectedColumnOrder.indexOf(column), column, true);
                };
            })

            it('should have correct gridoptions for designated jurisdictions', () => {
                initController();
                expect(o.id).toBe('caseview-designations');
                expect(o.pageable.pageSize).toBe(localSettings.Keys.caseView.designatedJurisdiction.pageNumber.getLocal);
                expect(o.pageable.pageSizes).toEqual([10, 20, 50, 100, 250]);
                expect(o.columnSelection.localSetting).toBe(localSettings.Keys.caseView.designatedJurisdiction.columnsSelection);
                o.read();
                expect(service.getCaseViewDesignatedJurisdictions).toHaveBeenCalled();
            });

            it('should initialise grid options of designated jurisdictions for internal user', () => {
                initController();
                expect(c.isExternal).toBeFalsy();
                expect(o).toBeDefined();
                expect(o.columns.length).toBe(expectedColumnOrder.length);

                validateColumn('jurisdiction');
                validateColumn('designatedStatus');
                validateColumn('officialNumber');
                validateColumn('caseStatus');
                validateColumn('internalReference');
                validateHiddenColumn('classes');
                validateHiddenColumn('priorityDate');
                validateHiddenColumn('isExtensionState');
                validateHiddenColumn('instructorReference');
                validateHiddenColumn('agentReference');

                expect(o.columns[5].title).toBe('caseview.designatedJurisdiction.internalReference');
                expect(o.columns[1].filterable).toBe(true);
                expect(o.columns[2].filterable).toBe(true);
                expect(o.columns[4].filterable).toBe(true);
            });

            it('should initialise grid options of designated jurisdictions for ip-platform user', () => {
                initController(null, null, {
                    file: {
                        isEnabled: true,
                        hasViewAccess: true
                    }
                });
                expect(c.isExternal).toBeFalsy();
                expect(o).toBeDefined();
                expect(o.columns.length).toBe(expectedColumnOrder.length);

                validateColumn('jurisdiction');
                validateColumn('designatedStatus');
                validateColumn('officialNumber');
                validateColumn('caseStatus');
                validateColumn('internalReference');
                validateHiddenColumn('classes');
                validateHiddenColumn('priorityDate');
                validateHiddenColumn('isExtensionState');
                validateHiddenColumn('instructorReference');
                validateHiddenColumn('agentReference');

                expect(o.columns[0].field).toBe('isFiled');
                expect(o.columns[0].menu).toBeFalsy();
            });

            it('should initialise grid options of designated jurisdictions for external user', () => {
                initController(null, true);
                expect(c.isExternal).toBeTruthy();
                expect(o).toBeDefined();
                expect(c.gridOptions.columns.length).toBe(expectedColumnOrder.length);
                validateColumn('jurisdiction');
                validateColumn('designatedStatus');
                validateColumn('officialNumber');
                validateColumn('caseStatus');
                validateColumn('clientReference');
                validateColumn('internalReference');
                validateHiddenColumn('classes');
                validateHiddenColumn('priorityDate');
                validateHiddenColumn('isExtensionState');
                expect(c.gridOptions.columns[6].title).toBe('caseview.designatedJurisdiction.ourReference');
                expect(o.columns[1].filterable).toBe(true);
                expect(o.columns[2].filterable).toBe(true);
                expect(o.columns[4].filterable).toBe(true);
            });
        });
    });
}