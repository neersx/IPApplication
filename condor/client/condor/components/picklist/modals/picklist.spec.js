describe('Modal controller inprotech.components.picklist.PicklistModalController', function() {
    'use strict';

    var createController, kendoGridBuilder, httpMock, modalInstance, persistenceService, apiResolverService, persistables,
        notificationService, api;

    beforeEach(function() {
        module('inprotech.components.picklist');

        module(function() {
            httpMock = test.mock('$http', 'httpMock');
            kendoGridBuilder = test.mock('kendoGridBuilder');
            modalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock');
            persistenceService = test.mock('persistenceService', 'PersistenceServiceMock');
            apiResolverService = test.mock('apiResolverService', 'ApiResolverServiceMock');
            persistables = test.mock('persistables', 'PersistablesMock');
            notificationService = test.mock('notificationService');

            api = {
                init: function(initRestmod) {
                    initRestmod({
                        columns: [{
                                key: true,
                                field: 'key'
                            },
                            {
                                description: true,
                                field: 'description'
                            }
                        ],
                        maintainabilityActions: {
                            allowAdd: true,
                            allowEdit: true,
                            allowDelete: true,
                            allowDuplicate: true
                        }
                    });
                },
                $search: jasmine.createSpy()
            };

            apiResolverService.resolve = jasmine.createSpy().and.returnValue(api);
            persistables.resolve = jasmine.createSpy().and.returnValue(api);
        });

        inject(function($rootScope, $controller) {
            createController = function(extOptions) {
                var scope = $rootScope.$new();

                var options = {
                    entity: "instructionTypes",
                    externalScope: {}
                };

                if (extOptions) {
                    _.extend(options, extOptions);
                }

                var retval = $controller('PicklistModalController', {
                    $log: angular.noop,
                    $scope: scope,
                    $uibModalInstance: modalInstance,
                    $http: httpMock,
                    apiResolverService: apiResolverService,
                    persistables: persistables,
                    persistenceService: persistenceService,
                    states: angular.noop,
                    notificationService: notificationService,
                    kendoGridBuilder: kendoGridBuilder,
                    store: {
                        local: {
                            get: function() {}
                        }
                    },
                    options: options,
                    validCombinationConfirmationService: angular.noop
                });

                retval.maintenance = {
                    $valid: true,
                    $setPristine: jasmine.createSpy()
                };

                retval.gridOptions.dataSource.get = function(key) {
                    return {
                        key: key,
                        description: 'description'
                    };
                };

                retval.gridOptions.dataSource.page = jasmine.createSpy().and.callThrough();
                retval.gridOptions.highlightAfterEditing = jasmine.createSpy();

                retval.entry = {
                    value: 'description'
                };

                retval.rawResults = {
                    $metadata: {
                        ids: [1, 333, 777]
                    }
                };

                return retval;
            };
        });
    });

    describe('grid update and highlight', function() {
        it('grid item reloaded and highlighted after editing', function() {
            var ctrl = createController();

            // this simulates editing item with key=1
            ctrl.changeToEditView({
                key: 333
            });

            // this simulates saving this item
            ctrl.save();

            // once saved, row must be refreshed and highlightened
            expect(ctrl.gridOptions.highlightAfterEditing).toHaveBeenCalled();
            expect(ctrl.gridOptions.highlightAfterEditing.calls.mostRecent().args[0].key).toEqual(333);
        });

        it('grid item highlighted after adding', function() {
            persistenceService.saveResult.key = 777;

            var ctrl = createController();
            ctrl.changeToAddView();

            // this simulates saving this item
            ctrl.save();

            // once saved, row must be refreshed and highlightened
            expect(ctrl.gridOptions.highlightAfterEditing).toHaveBeenCalled();
            expect(ctrl.gridOptions.highlightAfterEditing.calls.mostRecent().args[0].key).toEqual(777);
        });
    });

    describe('initially', function() {
        it('should initialise kendo grid', function() {
            createController();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });
        it('should run any initialise functions', function() {

            var extOptions = {
                initFunction: jasmine.createSpy().and.callThrough()
            }
            var c = createController(extOptions);
            expect(extOptions.initFunction).toHaveBeenCalledWith(c);
        });

        // it('should retrieve data from an endpoint service with correct parameters', function() {
        //     var ctrl = createController();
        //     ctrl.entity = 'Some';
        //     ctrl.searchValue = 'a';

        //     var results = ctrl.gridOptions.read();

        //     expect(api.$search).toHaveBeenCalled();
        //     expect(api.$search.calls.mostRecent().args[0].search).toEqual('a');
        //     expect(api.$search().$asPromise).toHaveBeenCalled();
        //     expect(results.data[0].$index).toBe(0);
        // });

        // it('should close the modal on selection', inject(function($uibModalInstance) {
        //     var ctrl = createController();
        //     ctrl.gridOptions.change();

        //     expect($uibModalInstance.close).toHaveBeenCalled();
        // }));
    });

    describe('when end user clicks on add, update or duplicate', function() {
        // it('should setup the right modal state', function() {
        //     var ctrl = createController();
        //     ctrl.changeToEditView({key:1});
        //     expect(ctrl.maintenanceState).toEqual('updating');

        //     ctrl.changeToDuplicateView({key:1});
        //     expect(ctrl.maintenanceState).toEqual('duplicating');

        //     ctrl.changeToAddView({key:1});
        //     expect(ctrl.maintenanceState).toEqual('adding');
        // });

        it('should call persistables to prepare modal to be maintained', function() {
            var ctrl = createController();
            ctrl.entity = 'Some';
            ctrl.changeToAddView();
            expect(persistables.prepare).toHaveBeenCalled();
        });
    });

    describe('when end user clicks save', function() {
        it('should save', function() {
            spyOn(persistenceService, 'save');

            var ctrl = createController();
            ctrl.save();

            expect(persistenceService.save).toHaveBeenCalled();
        });
    });

    describe('when end user deletes', function() {
        it('should set call persistables to prepare for the entity to be deleted', function() {
            var ctrl = createController();
            ctrl.gridOptions.removeItem = jasmine.createSpy();
            var selectedEntry = {
                key: 1,
                id: 1
            };
            ctrl.delete(selectedEntry);
            var deletedRow = _.filter(ctrl.rawResults.$metadata.ids, function(item) {
                return item == selectedEntry.key
            });

            expect(deletedRow.length).toEqual(0);
            expect(ctrl.rawResults.$metadata.ids.length).toEqual(2);
            expect(ctrl.gridOptions.removeItem).toHaveBeenCalled();
            expect(persistables.prepare).toHaveBeenCalled();
        });

        // it('should set call persistenceService to delete', function() {
        //     var ctrl = createController();
        //     ctrl.delete();
        //     expect(persistenceService.delete).toHaveBeenCalled();
        // });
    });

    describe('when end user cancels saving or deleting', function() {
        it('should abandon', function() {
            spyOn(persistenceService, 'abandon');

            var ctrl = createController();
            ctrl.abandon();

            expect(persistenceService.abandon).toHaveBeenCalled();
        });
    });

    describe('searching', function() {
        it('should call the grid search when not initialising', function() {
            var c = createController();
            c.modalState = 'normal';
            c.searchInWindow();
            expect(c.gridOptions.search).toHaveBeenCalled();
            expect(c.externalScope.picklistSearch).toBe(false);
        });

        it('should call the pre-search where available', function() {
            var extOptions = {
                preSearch: jasmine.createSpy().and.callThrough()
            };
            var c = createController(extOptions);
            c.modalState = 'normal';
            c.searchInWindow();
            expect(extOptions.preSearch).toHaveBeenCalledWith(c);
            expect(c.gridOptions.search).toHaveBeenCalled();
            expect(c.externalScope.picklistSearch).toBe(false);
        });

        it('should skip the pre-search if specified', function() {
            var extOptions = {
                preSearch: jasmine.createSpy().and.callThrough()
            };
            var c = createController();
            c.modalState = 'normal';
            c.searchInWindow(extOptions);
            c.searchInWindow(true);
            expect(extOptions.preSearch).not.toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
            expect(c.externalScope.picklistSearch).toBe(false);
        });

        it('should clear the selection on multi-pick pick lists when requested', function() {
            var c = createController({
                multipick: true
            });
            c.modalState = 'normal';
            c.selectedItems = ['a', 'b'];

            c.searchInWindow(true, false);
            expect(c.selectedItems.length).toEqual(2);

            c.searchInWindow(true, true);
            expect(c.selectedItems.length).toEqual(0);
        });

        it('should clear the selection on single-select pick lists when requested', function() {
            var c = createController({
                multipick: false
            });
            c.modalState = 'normal';
            c.selectedItem = {
                key: 'secret'
            };

            c.searchInWindow(true, false);
            expect(c.selectedItem.key).toEqual('secret');

            c.searchInWindow(true, true);
            expect(c.selectedItem).toBeNull();
        });
    });

    describe('update multi-pick selections', function() {
        it('should update selected items when an item is selected', function() {
            var c = createController();
            var item = {
                key: 0,
                selected: true
            };

            c.updateSelected(item);
            expect(c.selectedItems).toContain(item);
        });

        it('should update selected items when an item is unselected', function() {
            var c = createController();
            var item = {
                key: 0,
                selected: true
            };
            c.selectedItems = [item, {
                key: 1
            }];

            item.selected = false;

            c.updateSelected(item);
            expect(c.selectedItems.length).toEqual(1);
            expect(c.selectedItems).not.toContain(item);
        });
    });

    describe('when jurisdiction picklist edit button clicked', function() {
        it('should launch the jurisdiction maintenance in case of edit', function() {

            var c = createController();
            var item = {
                key: 'AF',
                selected: true
            };
            var options = {
                editUriState: 'jurisdictions.detail'
            };

            expect(c.changeToMaintenanceView('updating', item, options)).toBeFalsy();
        });

        it('should launch the jurisdiction maintenance in case of view', function() {

            var c = createController();
            var item = {
                key: 'AF',
                selected: true
            };
            var options = {
                editUriState: 'jurisdictions.detail'
            };

            expect(c.changeToMaintenanceView('viewing', item, options)).toBeFalsy();
        });
    });
});