describe('inprotech.configuration.general.importancelevel.ImportanceLevelController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, dataItemService, notificationService, modalService;


    beforeEach(function() {
        module('inprotech.configuration.general.dataitem');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.general.dataitem', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            dataItemService = $injector.get('DataItemServiceMock');
            $provide.value('dataItemService', dataItemService);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            test.mock('dateService');

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            scope = {};
            dependencies = angular.extend({
                $scope: scope,
                viewData: {}
            }, dependencies);

            return $controller('DataItemController', dependencies);
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables correctly', function() {
            var c = controller();
            c.$onInit();
            expect(c.gridOptions).toBeDefined();
        });
    });

    describe('initialize', function() {
        it('should initialize grid data', function() {
            var c = controller();
            c.$onInit();
            var response = {
                data: []
            };

            dataItemService.search = jasmine.createSpy().and.callFake(function() {
                return {
                    then: function(cb) {
                        cb(response);
                    }
                };
            });

            c.gridOptions.dataSource = {
                data: function(d) {
                    return d;
                }
            };

            c.gridOptions.data = function() {
                return [];
            };

            c.gridOptions.search();

            expect(c.gridOptions.data().length).toBe(0);
        });

    });

    describe('resetSearchCriteria', function() {
        it('should clear search results and criteria', function() {
            var c = controller();
            c.$onInit();
            c.resetSearchCriteria();
            expect(c.gridOptions.clear).toHaveBeenCalled();
            expect(c.searchCriteria.text).toBe(undefined);
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
    });

    describe('set font weight to bold if data item that is filtered is the current item group', function() {
        it('should return bold if the data item is the same as that is filtered', function() {
            var c = controller();
            c.$onInit();
            c.searchCriteria.group = [{
                key: 1
            }, {
                key: 2
            }];
            var group = {
                code: 1
            }
            expect(c.highlightFilteredGroup(group)).toBe('bold');
        });
        it('should return null if the item group is the same as that is filtered', function() {
            var c = controller();
            c.$onInit();
            c.searchCriteria.group = [{
                key: 1
            }, {
                key: 2
            }];
            var group = {
                code: 3
            }
            expect(c.highlightFilteredGroup(group)).toBe(undefined);
        });
    });
    describe('add data item', function() {
        it('should call modalService and entity state should be adding', function() {
            var c = controller();
            c.$onInit();
            c.add();

            var entity = {
                isSqlStatement: true,
                state: "adding"
            };
            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'DataItemMaintenanceConfig',
                    controllerAs: 'vm',
                    entity: entity
                })));
        });
    });

    function getElementById(items, name) {
        return _.find(items, function(item) {
            return item.id === name;
        });
    }

    describe('edit data item', function() {
        it('should not be available if no record is selected', function() {
            var c = controller();
            c.$onInit();
            c.gridOptions.data = function() {
                return [{
                    id: 1
                }, {
                    id: 2
                }];
            };
            expect(getElementById(c.dataItems, 'edit').enabled()).toBe(false);
        });
        it('should be available if record is selected', function() {
            var c = controller();
            c.$onInit();
            c.gridOptions.data = function() {
                return [{
                    id: 1,
                    selected: true
                }, {
                    id: 2
                }];
            };
            expect(getElementById(c.dataItems, 'edit').enabled()).toBe(true);
        });
        it('should call modalService and entity state should be updating', function() {
            var c = controller();
            c.$onInit();
            c.gridOptions.data = function() {
                return [{
                    id: 1,
                    selected: true
                }, {
                    id: 2
                }];
            };

            var entity = {
                id: 1,
                state: "updating"
            };

            c.edit(1);

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'DataItemMaintenanceConfig',
                    controllerAs: 'vm',
                    entity: entity
                })));
        });
    });

    describe('delete data items types', function() {
        it('should call notification success and should initialize the grid', function() {
            var c = controller();
            c.$onInit();
            c.gridOptions.data = function() {
                return [{
                    id: 1,
                    selected: true
                }, {
                    id: 2,
                    selected: false
                }, {
                    id: 3,
                    selected: true
                }];
            };

            var response = {
                data: {
                    message: 'deleted'
                }
            };

            dataItemService.delete = jasmine.createSpy().and.callFake(function() {
                return {
                    then: function(cb) {
                        cb(response);
                    }
                };
            });


            c.deleteSelectedDataItems();

            expect(dataItemService.delete).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
    });
});