describe('Jurisdictions Controller', function() {
    'use strict';

    var controller, kendoGridBuilder, state, hotkeys, notificationService, promiseMock, maintenanceService, bulkMenuOperationsMock;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.grid', 'inprotech.mocks']);
            $provide.value('jurisdictionsService', $injector.get('JurisdictionsServiceMock'));

            maintenanceService = test.mock('jurisdictionMaintenanceService', 'JurisdictionMaintenanceServiceMock');

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            hotkeys = $injector.get('hotkeysMock');
            $provide.value('hotkeys', hotkeys);

            notificationService = test.mock('notificationService');
            promiseMock = test.mock('promise');

            bulkMenuOperationsMock = $injector.get('BulkMenuOperationsMock');
            $provide.value('BulkMenuOperations', bulkMenuOperationsMock);
        });
    });

    beforeEach(inject(function($controller, $state) {
        state = $state;
        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: {},
                viewData: {},
                initialData: {
                    canMaintain: true,
                    viewOnly: false
                }
            }, dependencies);

            return $controller('JurisdictionsController', dependencies);
        };
    }));

    describe('initialisation', function() {
        var c;
        beforeEach(function() {
            hotkeys.add = jasmine.createSpy('add() spy').and.callThrough();
        });
        it('should initialise the properties', function() {
            c = controller();
            c.$onInit();
            expect(c.search).toBeDefined();
            expect(c.reset).toBeDefined();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(c.searchCriteria.text).toBe('');
            expect(c.permissions).toEqual({
                canMaintain: true,
                viewOnly: false
            });
        });
        it('and build the menu', function() {
            c = controller();
            c.$onInit();
            expect(c.menu).toEqual({
                context: 'jurisdictionMenu',
                items: [{
                    id: 'edit',
                    enabled: jasmine.any(Function),
                    maxSelection: 1,
                    click: jasmine.any(Function)
                }, {
                    id: 'delete',
                    enabled: jasmine.any(Function),
                    click: jasmine.any(Function)
                }, {
                    id: 'changeCode',
                    text: 'jurisdictions.changeCode.changeJurisdictionCode',
                    icon: 'cpa-icon cpa-icon-pencil-square-o',
                    enabled: jasmine.any(Function),
                    click: jasmine.any(Function),
                    maxSelection: 1
                }],
                clearAll: jasmine.any(Function),
                selectionChange: jasmine.any(Function),
                selectPage: jasmine.any(Function)
            });
        });
        it('but disable add keyboard shortcut if unauthorised', function() {
            c = controller({
                initialData: {
                    canMaintain: false,
                    viewOnly: true
                }
            });
            c.$onInit();
            expect(c.search).toBeDefined();
            expect(c.reset).toBeDefined();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(c.searchCriteria.text).toBe('');
            expect(c.permissions).toEqual({
                canMaintain: false,
                viewOnly: true
            });
            expect(hotkeys.add).not.toHaveBeenCalled();
        });
    });

    describe('searching', function() {
        it('should invoke service to perform search', function() {
            var c = controller();
            c.$onInit();
            c.search();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
        it('should clear the grid when performing the search', function() {
            var c = controller();
            c.$onInit();
            c.search();
            expect(c.gridOptions.clear).toHaveBeenCalled();
        });
        it('should clear search results when Clear button is clicked', function() {
            var c = controller();
            c.$onInit();
            c.reset();
            expect(c.gridOptions.clear).toHaveBeenCalled();
        });
    });

    describe('reset', function() {
        it('should clear search results and criteria', function() {
            var c = controller();
            c.$onInit();
            c.reset();
            expect(c.gridOptions.clear).toHaveBeenCalled();
            expect(c.searchCriteria.text).toBe('');
        });
    });

    describe('maintain', function() {
        it('should transition to detail state', function() {
            var c = controller();
            c.$onInit();
            var dataItemId = 'ABC';
            expect(state.href('jurisdictions')).toEqual('#/configuration/general/jurisdictions');

            c.maintain(dataItemId);
            expect(state.href('jurisdictions.detail', {
                id: dataItemId
            })).toEqual('#/configuration/general/jurisdictions/maintenance/' + dataItemId);
        });
    });

    describe('from the bulk menu', function() {
        var c;
        beforeEach(function() {
            c = controller();
            c.$onInit();
            c.gridOptions = {
                data: function() {
                    return false;
                }
            };
            spyOn(c.gridOptions, 'data').and.returnValue(
                [{
                    id: 'abc',
                    selected: true,
                    inUse: false
                }, {
                    id: 'xyz',
                    selected: false,
                    inUse: false
                }, {
                    id: '123',
                    selected: true,
                    inUse: false
                }]);
            spyOn(c, 'maintain').and.callThrough();
            bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([{
                id: 'abc'
            }, {
                id: '123'
            }]);
        });
        describe('edit option', function() {
            it('displays details of selected jurisdiction', function() {
                _.findWhere(c.menu.items, {
                    id: 'edit'
                }).click();
                expect(c.maintain).toHaveBeenCalledWith(['abc', '123']);
            });
        });
        describe('delete option', function() {
            beforeEach(function() {
                maintenanceService.delete = promiseMock.createSpy({
                    data: {
                        result: 'success',
                        id: 'abc'
                    }
                });
                c.gridOptions.search = promiseMock.createSpy({});

                state.reload = jasmine.createSpy('reload spy()').and.callThrough();
            });
            it('displays confirmation dialog', function() {
                _.findWhere(c.menu.items, {
                    id: 'delete'
                }).click();
                expect(notificationService.confirmDelete).toHaveBeenCalledWith({
                    message: 'modal.confirmDelete.message'
                });
            });
            it('calls delete service', function() {
                _.findWhere(c.menu.items, {
                    id: 'delete'
                }).click();
                expect(maintenanceService.delete).toHaveBeenCalledWith(['abc', '123']);
            });
            it('displays the success notification', function() {
                _.findWhere(c.menu.items, {
                    id: 'delete'
                }).click();
                expect(notificationService.success).toHaveBeenCalled();
                expect(c.gridOptions.search).toHaveBeenCalled();
            });
            it('displays the error notification when unsuccessful', function() {
                maintenanceService.delete = promiseMock.createSpy({
                    data: {
                        result: 'error',
                        errors: {}
                    }
                });
                _.findWhere(c.menu.items, {
                    id: 'delete'
                }).click();
                expect(notificationService.alert).toHaveBeenCalledWith({
                    title: 'modal.unableToComplete',
                    message: 'modal.alert.alreadyInUse'
                });
                expect(notificationService.success).not.toHaveBeenCalled();
                expect(c.gridOptions.search).toHaveBeenCalled();
            });
            it('marks unsuccessful deletes', function() {
                maintenanceService.delete = promiseMock.createSpy({
                    data: {
                        result: 'error',
                        errors: [{
                            id: '123'
                        }]
                    }
                });
                _.findWhere(c.menu.items, {
                    id: 'delete'
                }).click();
                var list = c.gridOptions.data();
                expect(notificationService.alert).toHaveBeenCalledWith({
                    title: 'modal.unableToComplete',
                    message: 'modal.alert.alreadyInUse'
                });
                expect(notificationService.success).not.toHaveBeenCalled();
                expect(c.gridOptions.search).toHaveBeenCalled();
                expect(list[0].inUse).toBe(false);
                expect(list[1].inUse).toBe(false);
            });
        });
    });
});