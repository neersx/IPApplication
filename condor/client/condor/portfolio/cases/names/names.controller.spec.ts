'use strict';

namespace inprotech.portfolio.cases {
    describe('case view names controller', () => {

        let controller, service: ICaseviewNamesService, kendoGridBuilder, localSettings, store, displayableFields;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(() => {

            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                service = $injector.get<ICaseviewNamesService>('caseviewNamesServiceMock');
                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                store = $injector.get('storeMock');
                localSettings = new inprotech.core.LocalSettings(store);
                displayableFields = new DisplayableNameTypeFieldsHelper();
            });

            inject(($rootScope) => {
                let scope = $rootScope.$new();
                controller = (viewData?: any, topic?: any) => {
                    let c = new CaseviewNamesController(scope, kendoGridBuilder, service, localSettings, displayableFields);
                    c.viewData = viewData || {};
                    c.topic = topic;
                    return c;
                };
            });
        });

        describe('initialize with displayNameVariants', () => {
            let viewData = {
                caseKey: 1,
                displayNameVariants: true
            };
            let topic = {
                filters: {
                    nameTypeKey: 'o'
                }
            }

            it('should initialise grid options for internal users', () => {
                let c = controller(viewData, topic);
                c.isExternal = false;
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(store.local.get).toHaveBeenCalled();
                expect(c.gridOptions.columns.length).toBe(6);
                expect(c.gridOptions.columns[0].field).toBe('type');
                expect(c.gridOptions.columns[1].field).toBe('shouldCheckRestrictions');
                expect(c.gridOptions.columns[2].field).toBe('name');
                expect(c.gridOptions.columns[3].field).toBe('nameVariant');
                expect(c.gridOptions.columns[4].field).toBe('attention');
                expect(c.gridOptions.columns[5].field).toBe('reference');
            });

            it('should initialise grid options for external users', () => {
                let c = controller(viewData, topic);
                c.isExternal = true;
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(store.local.get).toHaveBeenCalled();
                expect(c.gridOptions.columns.length).toBe(5);
                expect(c.gridOptions.columns[0].field).toBe('type');
                expect(c.gridOptions.columns[1].field).toBe('name');
                expect(c.gridOptions.columns[2].field).toBe('nameVariant');
                expect(c.gridOptions.columns[3].field).toBe('attention');
                expect(c.gridOptions.columns[4].field).toBe('reference');
            });
        });

        describe('initialize without displayNameVariants', () => {
            let viewData = {
                caseKey: 1,
                displayNameVariants: false
            };
            let topic = {
                filters: {
                    nameTypeKey: 'o'
                }
            }

            it('should initialise grid options for internal users', () => {
                let c = controller(viewData, topic);
                c.isExternal = false;
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(store.local.get).toHaveBeenCalled();
                expect(c.gridOptions.columns.length).toBe(5);
                expect(c.gridOptions.columns[0].field).toBe('type');
                expect(c.gridOptions.columns[1].field).toBe('shouldCheckRestrictions');
                expect(c.gridOptions.columns[2].field).toBe('name');
                expect(c.gridOptions.columns[3].field).toBe('attention');
                expect(c.gridOptions.columns[4].field).toBe('reference');
            });

            it('should initialise grid options for external users', () => {
                let c = controller(viewData, topic);
                c.isExternal = true;
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(store.local.get).toHaveBeenCalled();
                expect(c.gridOptions.columns.length).toBe(4);
                expect(c.gridOptions.columns[0].field).toBe('type');
                expect(c.gridOptions.columns[1].field).toBe('name');
                expect(c.gridOptions.columns[2].field).toBe('attention');
                expect(c.gridOptions.columns[3].field).toBe('reference');
            });
        });
        describe('initialize with hasBillPercentageDisplayed set for name type key', () => {
            let viewData = {
                caseKey: 1,
                displayNameVariants: false,
                hasBillPercentageDisplayed: [
                    'o'
                ]
            };
            let topic = {
                filters: {
                    nameTypeKey: 'o'
                }
            }

            it('should initialise to display bill poercentage column', () => {
                let c = controller(viewData, topic);
                c.isExternal = false;
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(store.local.get).toHaveBeenCalled();
                expect(c.gridOptions.columns.length).toBe(6);
                expect(c.gridOptions.columns[0].field).toBe('type');
                expect(c.gridOptions.columns[1].field).toBe('shouldCheckRestrictions');
                expect(c.gridOptions.columns[2].field).toBe('name');
                expect(c.gridOptions.columns[3].field).toBe('attention');
                expect(c.gridOptions.columns[4].field).toBe('reference');
                expect(c.gridOptions.columns[5].field).toBe('billingPercentage');
            });
        });
        describe('initialize with hasBillPercentageDisplayed set for different name type key', () => {
            let viewData = {
                caseKey: 1,
                displayNameVariants: false,
                hasBillPercentageDisplayed: [
                    'o'
                ]
            };
            let topic = {
                filters: {
                    nameTypeKey: 'A'
                }
            }

            it('should initialise to display bill poercentage column', () => {
                let c = controller(viewData, topic);
                c.isExternal = false;
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(store.local.get).toHaveBeenCalled();
                expect(c.gridOptions.columns.length).toBe(5);
                expect(c.gridOptions.columns[0].field).toBe('type');
                expect(c.gridOptions.columns[1].field).toBe('shouldCheckRestrictions');
                expect(c.gridOptions.columns[2].field).toBe('name');
                expect(c.gridOptions.columns[3].field).toBe('attention');
                expect(c.gridOptions.columns[4].field).toBe('reference');
            });
        });
        describe('initialize with hasBillPercentageDisplayed not set for name type key', () => {
            let viewData = {
                caseKey: 1,
                displayNameVariants: false,
                hasBillPercentageDisplayed: []
            };
            let topic = {
                filters: {
                    nameTypeKey: 'o'
                }
            }

            it('should initialise to hide bill poercentage column', () => {
                let c = controller(viewData, topic);
                c.isExternal = false;
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(store.local.get).toHaveBeenCalled();
                expect(c.gridOptions.columns.length).toBe(5);
                expect(c.gridOptions.columns[0].field).toBe('type');
                expect(c.gridOptions.columns[1].field).toBe('shouldCheckRestrictions');
                expect(c.gridOptions.columns[2].field).toBe('name');
                expect(c.gridOptions.columns[3].field).toBe('attention');
                expect(c.gridOptions.columns[4].field).toBe('reference');
            });
        });
        describe('initialize with hasBillPercentageDisplayed set for name type key, but no name type key filter', () => {
            let viewData = {
                caseKey: 1,
                displayNameVariants: false,
                hasBillPercentageDisplayed: [
                    'o'
                ]
            };
            let topic = {
                filters: {
                    nameTypeKey: ''
                }
            }

            it('should initialise to hide bill poercentage column', () => {
                let c = controller(viewData, topic);
                c.isExternal = false;
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(store.local.get).toHaveBeenCalled();
                expect(c.gridOptions.columns.length).toBe(5);
                expect(c.gridOptions.columns[0].field).toBe('type');
                expect(c.gridOptions.columns[1].field).toBe('shouldCheckRestrictions');
                expect(c.gridOptions.columns[2].field).toBe('name');
                expect(c.gridOptions.columns[3].field).toBe('attention');
                expect(c.gridOptions.columns[4].field).toBe('reference');
            });
        });
        describe('initialize with hasBillPercentageDisplayed not set for name type key, and no name type key filter', () => {
            let viewData = {
                caseKey: 1,
                displayNameVariants: false,
                hasBillPercentageDisplayed: []
            };
            let topic = {
                filters: {
                    nameTypeKey: ''
                }
            }

            it('should initialise to hide bill poercentage column', () => {
                let c = controller(viewData, topic);
                c.isExternal = false;
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(store.local.get).toHaveBeenCalled();
                expect(c.gridOptions.columns.length).toBe(5);
                expect(c.gridOptions.columns[0].field).toBe('type');
                expect(c.gridOptions.columns[1].field).toBe('shouldCheckRestrictions');
                expect(c.gridOptions.columns[2].field).toBe('name');
                expect(c.gridOptions.columns[3].field).toBe('attention');
                expect(c.gridOptions.columns[4].field).toBe('reference');
            });
        });
        describe('allow expansions', () => {
            let viewData = {
                caseKey: 1,
                displayNameVariants: false
            };
            let topic = {
                filters: {}
            }

            it('should allow expansion when address is set to be displayed', () => {
                let c = controller(viewData, topic);
                let r = c.hasDetails({
                    displayFlags: NameTypeFieldFlags.address
                });
                expect(r).toBe(true);
            });

            it('should allow expansion when assignment date is set to be displayed', () => {
                let c = controller(viewData, topic);
                let r = c.hasDetails({
                    displayFlags: NameTypeFieldFlags.assignDate
                });
                expect(r).toBe(true);
            });

            it('should allow expansion when date commence is set to be displayed', () => {
                let c = controller(viewData, topic);
                let r = c.hasDetails({
                    displayFlags: NameTypeFieldFlags.dateCommenced
                });
                expect(r).toBe(true);
            });

            it('should allow expansion when date ceased is set to be displayed', () => {
                let c = controller(viewData, topic);
                let r = c.hasDetails({
                    displayFlags: NameTypeFieldFlags.dateCeased
                });
                expect(r).toBe(true);
            });

            it('should allow expansion when bill percentage is set to be displayed', () => {
                let c = controller(viewData, topic);
                let r = c.hasDetails({
                    displayFlags: NameTypeFieldFlags.billPercentage
                });
                expect(r).toBe(true);
            });

            it('should allow expansion when remarks is set to be displayed', () => {
                let c = controller(viewData, topic);
                let r = c.hasDetails({
                    displayFlags: NameTypeFieldFlags.remarks
                });
                expect(r).toBe(true);
            });

            it('should allow expansion when end user is allowed to view email and phone', () => {
                let c = controller(viewData, topic);
                let r = c.hasDetails({
                    displayFlags: NameTypeFieldFlags.telecom
                });
                expect(r).toBe(true);
            });
        });

        describe('prevent expansions', () => {
            let viewData = {
                caseKey: 1,
                displayNameVariants: false
            };
            let topic = {
                filters: {}
            }

            it('should prevent expansion when inherited is set to be displayed', () => {
                let c = controller(viewData, topic);
                let r = c.hasDetails({
                    displayFlags: NameTypeFieldFlags.inherited
                });
                expect(r).toBe(false);
            });
        });
    });
}