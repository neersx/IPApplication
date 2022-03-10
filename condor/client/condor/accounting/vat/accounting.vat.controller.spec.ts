namespace inprotech.accounting.vat {
    describe('inprotech.accounting.vat', () => {
        'use strict';
        let controller: (viewData: any, modalMock ?: any) => AccountingVatController,
            dateHelper: any,
            service: any,
            _location: any,
            promiseMock: any,
            _window: any,
            store: any,
            modalService: any;

        beforeEach(() => {
            angular.mock.module('inprotech.accounting.vat');

            inject(($rootScope, $location) => {
                let $injector: ng.auto.IInjectorService = angular.injector([
                    'inprotech.mocks',
                    'inprotech.mocks.core'
                ]);
                let scope = $rootScope.$new();
                _location = $location;
                store = $injector.get('storeMock');
                service = $injector.get('VatReturnsServiceMock');
                let localSettings = new inprotech.core.LocalSettings(store);
                let kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                let dateService = $injector.get('dateServiceMock');
                modalService = $injector.get('modalServiceMock');
                dateHelper = $injector.get('dateHelperMock');
                spyOn(dateHelper, 'convertForDatePicker').and.callThrough();
                promiseMock = $injector.get < any > ('promiseMock');
                _window = {
                    location: {
                        href: ''
                    }
                };
                service.initialiseHmrcHeaders = promiseMock.createSpy({});
                controller = (viewData: any, modalMock ?: any) => {
                    if (modalMock) {
                        modalService = modalMock;
                    }
                    let c = new AccountingVatController(
                        scope,
                        _location,
                        _window,
                        service,
                        kendoGridBuilder,
                        localSettings,
                        dateService,
                        dateHelper,
                        modalService,
                        store
                    );
                    angular.extend(c, viewData);
                    return c;
                };
            });
        });

        describe('initialize', () => {
            it('should set the required default properties', () => {
                let c = controller({
                    viewData: {
                        noVatNumber: null,
                        entityNames: [{
                            displayName: 'theEntity1',
                            taxCode: 'abc123'
                        }]
                    }
                });
                expect(c.vm).toBeDefined();

                c.$onInit();
                expect(c.vm.formData.open).toBe(true);
                expect(c.vm.formData.fulfilled).toBe(false);
                expect(c.gridOptions).toBeDefined();
            });
            it('should restore the filter to the stored state', () => {
                let fromDate = new Date();
                let toDate = new Date();
                toDate.setDate(28);
                store = {
                    session: {
                        get: jasmine.createSpy().and.returnValue({ '___theStateKey___': { 'fromDate': fromDate, 'toDate': toDate, 'open': false, 'fulfilled': true} })
                    }
                };
                let c = controller({
                    viewData: {
                        noVatNumber: null,
                        stateId: '___theStateKey___',
                        entityNames: [{
                            displayName: 'theEntity1',
                            taxCode: 'abc123'
                        }]
                    }
                });

                service.authorise = promiseMock.createSpy({}, true);
                c.$onInit();
                expect(c.vm.formData).toBeDefined();
                expect(c.vm.formData.open).toBe(false);
                expect(c.vm.formData.fulfilled).toBe(true);
                expect(dateHelper.convertForDatePicker).toHaveBeenCalledWith(fromDate);
                expect(dateHelper.convertForDatePicker).toHaveBeenCalledWith(toDate);
                expect(c.vm.formData.fromDate.toISOString()).toBe(fromDate.toISOString());
                expect(c.vm.formData.toDate.toISOString()).toBe(toDate.toISOString());
                expect(c.gridOptions).toBeDefined();
            });
            it('should default to filter on Open status if state is available but status filter not set', () => {
                store = {
                    session: {
                        get: jasmine.createSpy().and.returnValue({ '___theStateKey___': {} })
                    }
                };
                let c = controller({
                    viewData: {
                        noVatNumber: null,
                        stateId: '___theStateKey___',
                        entityNames: [{
                            displayName: 'theEntity1',
                            taxCode: 'abc123'
                        }]
                    }
                });
                service.authorise = promiseMock.createSpy({}, true);
                c.$onInit();
                expect(c.vm.formData).toBeDefined();
                expect(c.vm.formData.open).toBe(true);
                expect(c.vm.formData.fulfilled).toBeFalsy();
                expect(c.gridOptions).toBeDefined();
            });
        });

        describe('when unticking status options', () => {
            it('automatically ticks the other option', () => {
                let c = controller({
                    viewData: {
                        fulfilled: false,
                        open: true,
                        entityNames: [{
                            displayName: 'theEntity1',
                            taxCode: 'abc123'
                        }]
                    }
                });
                c.$onInit();
                c.clickStatus('open');
                expect(c.formData.fulfilled).toBe(true);

                c.clickStatus('fulfilled');
                expect(c.formData.open).toBe(true);
            });
        });

        describe('when an VAT group is selected', () => {
            it('sets the entity group correctly', () => {
                let c = controller({
                    viewData: {
                        entityNames: [{
                            displayName: 'theEntity1',
                            taxCode: 'abc123'
                        }, {
                            displayName: 'theEntity2',
                            taxCode: 'abc123'
                        }]
                    }
                });
                c.$onInit();
                c.formData.entityName = {
                    taxCode: 'abc123'
                };
                c.onEntitySelected();
                expect(c.formData.multipleEntitiesSelected).toBe(true);
                expect(c.formData.selectedEntitiesNames).toBe('theEntity1, theEntity2.');
            });
        });

        describe('when an entity is selected', () => {
            it('sets the flag correctly', () => {
                let c = controller({
                    viewData: {
                        entityNames: [{
                            displayName: 'theEntity1',
                            taxCode: 'abc123'
                        }]
                    }
                });
                c.$onInit();
                c.formData.entityName = {
                    taxCode: null
                };
                expect(c.vm.noVatNumber()).toBe(false);
                c.formData.entityName = {
                    taxCode: 'abc123'
                };
                expect(c.vm.noVatNumber()).toBe(false);
                c.formData.entityName = {
                    displayName: 'theEntity',
                    taxCode: 'abc123'
                };
                expect(c.vm.noVatNumber()).toBe(false);
                c.formData.entityName = {
                    displayName: 'theEntity',
                    taxCode: null
                };
                expect(c.vm.noVatNumber()).toBe(true);
            });
        });

        describe('when Search is clicked', () => {
            describe('if there is an access allowed', () => {
                it('runs the search and displays the header', () => {
                    let c = controller({
                        viewData: {
                            hasResults: false,
                            entityNames: [{
                                displayName: 'theEntity1',
                                taxCode: 'abc123'
                            }]
                        }
                    });
                    c.form = {
                        $validate: jasmine.createSpy().and.callThrough()
                    };
                    c.$onInit();
                    c.search();
                    expect(c.gridOptions.search).toHaveBeenCalled();
                    expect(c.vm.viewData.hasResults).toBe(true);
                })
            })

            describe('if there is an access not allowed', () => {
                it('redirects to hmrc authorisation page', () => {
                    let c = controller({
                        viewData: {
                            hasResults: false,
                            entityNames: [{
                                displayName: 'theEntity1',
                                taxCode: 'abc123'
                            }]
                        }
                    });
                    c.form = {
                        $validate: jasmine.createSpy().and.callThrough()
                    };
                    c.service.getObligations = promiseMock.createSpy({readyToRedirect: 'ok'});
                    c.redirectOnAuth = jasmine.createSpy().and.callThrough();
                    c.$onInit();
                    c.authoriseRead()
                    expect(c.redirectOnAuth).toHaveBeenCalled();
                })
            })
        });

        describe('when the search is cleared', () => {
            it('resets the search data and results', () => {
                let c = controller({
                    viewData: {
                        hasResults: false,
                        entityNames: [{
                            displayName: 'theEntity1',
                            taxCode: 'abc123'
                        }]
                    }
                });
                c.form = {
                    $setPristine: jasmine.createSpy().and.callThrough(),
                    $reset: jasmine.createSpy().and.callThrough()
                };
                c.$onInit();
                c.formData = {
                    entityName: [{
                        displayName: 'TheEntity',
                        taxCode: '1234-abc'
                    }],
                    fromDate: new Date(),
                    toDate: new Date(),
                    open: false,
                    fulfilled: true
                };
                c.viewData.hasResults = true;
                c.clear();
                expect(c.gridOptions.clear).toHaveBeenCalled();
                expect(c.vm.viewData.hasResults).toBe(false);
                expect(c.formData.fromDate).toBeFalsy();
                expect(c.formData.toDate).toBeFalsy();
                expect(c.formData.entityName).toBeDefined();
                expect(c.formData.open).toBe(true);
                expect(c.formData.fulfilled).toBe(false);
            })
        });

        describe('when Submit button is clicked', () => {
            it('opens modal', () => {
                let fromDate = new Date();
                let toDate = new Date();
                let periodKey = '__thePeriod123__';
                let c = controller({
                    viewData: {
                        hasResults: true,
                        entityNames: [{
                            displayName: 'theEntity1',
                            taxCode: 'abc123'
                        }]
                    }
                });
                c.selectedEntitiesNames = '';
                c.searchedEntity = {
                    id: -2777831,
                    displayName: '__TheEntity__',
                    taxCode: 'Abc123Xyz'
                }
                c.search = jasmine.createSpy().and.callThrough();
                c.vatSubmitter(fromDate, toDate, periodKey);
                expect(modalService.openModal).toHaveBeenCalledWith({
                    id: 'VatSubmitterDialog',
                    controllerAs: 'vm',
                    entityNameNo: -2777831,
                    fromDate: fromDate,
                    toDate: toDate,
                    entityName: '__TheEntity__',
                    entityTaxCode: 'Abc123Xyz',
                    periodKey: '__thePeriod123__',
                    selectedEntitiesNames: ''
                });
                expect(c.search).not.toHaveBeenCalled();
            });
            it('opens modal and reruns search when closed', () => {
                let fromDate = new Date();
                let toDate = new Date();
                let periodKey = '__thePeriod123__';
                let modalMock = {
                    openModal: promiseMock.createSpy({
                        result: 'OK'
                    })
                };
                let c = controller({
                    viewData: [{
                        hasResults: true,
                        entityNames: {
                            displayName: 'theEntity1',
                            taxCode: 'abc123'
                    }
                    }]
                }, modalMock);
                c.selectedEntitiesNames = '';
                c.searchedEntity = {
                    id: -2777831,
                    displayName: '__TheEntity__',
                    taxCode: 'Abc123Xyz'
                }
                c.search = jasmine.createSpy().and.callThrough();
                c.vatSubmitter(fromDate, toDate, periodKey);
                expect(modalService.openModal).toHaveBeenCalledWith({
                    id: 'VatSubmitterDialog',
                    controllerAs: 'vm',
                    entityNameNo: -2777831,
                    fromDate: fromDate,
                    toDate: toDate,
                    entityName: '__TheEntity__',
                    entityTaxCode: 'Abc123Xyz',
                    periodKey: '__thePeriod123__',
                    selectedEntitiesNames: ''
                });
                expect(c.search).toHaveBeenCalled();
            });

            it('opens modal and display modal popup for multiple entities', () => {

                let fromDate = new Date();
                let toDate = new Date();
                let periodKey = '__thePeriod123__';

                let c = controller({
                    viewData: {
                        entityNames: [{
                            displayName: 'theEntity1',
                            taxCode: 'abc123'
                        }, {
                            displayName: 'theEntity2',
                            taxCode: 'abc123'
                        }],
                        hasResults: true
                    }
                });
                c.searchedEntity = {
                    id: -2777831,
                    displayName: 'theEntity1',
                    taxCode: 'abc123'
                }
                c.selectedEntitiesNames = 'theEntity1, theEntity2.';
                c.search = jasmine.createSpy().and.callThrough();
                c.vatSubmitter(fromDate, toDate, periodKey);
                expect(modalService.openModal).toHaveBeenCalledWith({
                    id: 'VatSubmitterDialog',
                    controllerAs: 'vm',
                    entityNameNo: -2777831,
                    fromDate: fromDate,
                    toDate: toDate,
                    entityName: 'theEntity1',
                    entityTaxCode: 'abc123',
                    periodKey: '__thePeriod123__',
                    selectedEntitiesNames: 'theEntity1, theEntity2.'
                });
                expect(c.search).not.toHaveBeenCalled();
            });
        });
    });
}