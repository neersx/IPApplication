describe('inprotech.configuration.general.numbertypes.NumberTypesController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, notificationService, modalService, numberTypesService;

    beforeEach(function() {
        module('inprotech.configuration.general.numbertypes');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.general.numbertypes', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            numberTypesService = $injector.get('NumberTypeServiceMock');
            $provide.value('numberTypesService', numberTypesService);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

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

            var c = $controller('NumberTypesController', dependencies);
            c.$onInit();
            return c;
        };
    }));

    function getElementById(items, name) {
        return _.find(items, function(item) {
            return item.id === name;
        });
    }

    describe('initialize view model', function() {
        it('should initialize grid builder options along with search criteria', function() {
            var c = controller();

            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.context).toBe('numbertypes');
            expect(c.searchCriteria.text).toBe('');
        });
    });

    describe('initialize', function() {
        it('should initialize grid data', function() {
            var c = controller();
            var response = {
                data: [{
                    id: 1
                }, {
                    id: 2
                }]
            };

            numberTypesService.search = jasmine.createSpy().and.callFake(function() {
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
                return response.data;
            };

            c.gridOptions.getQueryParams = function() {
                return null;
            };

            c.search();

            expect(c.gridOptions.data().length).toBe(2);
        });
        it('should initialize grid data', function() {
            var c = controller();
            var response = {
                data: []
            };

            numberTypesService.search = jasmine.createSpy().and.callFake(function() {
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

            c.gridOptions.getQueryParams = function() {
                return null;
            };

            c.search();

            expect(c.gridOptions.data().length).toBe(0);
        });

    });
    describe('add number type', function() {
        it('should call modalService and entity state should be adding', function() {
            var c = controller();
            c.add();

            var entity = {
                state: "adding"
            };
            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'NumberTypeMaintenance',
                    controllerAs: 'vm',
                    entity: entity,
                    allItems: c.gridOptions.data(),
                    dataItem: getElementById(c.gridOptions.data(), entity.id)
                })));
        });
    });
    describe('edit number type', function() {
        it('should not be available if no record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 1
                }, {
                    id: 2
                }];
            };
            expect(getElementById(c.numberTypes, 'edit').enabled()).toBe(false);
        });
        it('should be available if record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 1,
                    selected: true
                }, {
                    id: 2
                }];
            };
            expect(getElementById(c.numberTypes, 'edit').enabled()).toBe(true);
        });
        it('should call modalService and entity state should be updating', function() {
            var c = controller();
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
                    id: 'NumberTypeMaintenance',
                    controllerAs: 'vm',
                    entity: entity,
                    allItems: c.gridOptions.data(),
                    dataItem: getElementById(c.gridOptions.data(), entity.id)
                })));
        });
    });
    describe('duplicate number type', function() {
        it('should not be available if no record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 1
                }, {
                    id: 2
                }];
            };
            expect(getElementById(c.numberTypes, 'duplicate').enabled()).toBe(false);
        });
        it('should be available if record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 1,
                    selected: true
                }, {
                    id: 2
                }];
            };
            expect(getElementById(c.numberTypes, 'duplicate').enabled()).toBe(true);
        });
        it('should call modalService and entity state should be duplicating', function() {
            var c = controller();
            var entity = {
                id: null,
                state: "duplicating"
            };
            c.gridOptions.data = function() {
                return [{
                    id: 1,
                    selected: true
                }, {
                    id: 2
                }];
            };

            c.duplicate();
            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'NumberTypeMaintenance',
                    controllerAs: 'vm',
                    entity: entity,
                    allItems: c.gridOptions.data(),
                    dataItem: getElementById(c.gridOptions.data(), entity.id)
                })));
        });
    });
    describe('delete number types', function() {
        it('should call notification success and should initialize the grid', function() {
            var c = controller();
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

            spyOn(numberTypesService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });

            c.deleteSelectedNumberTypes();

            expect(numberTypesService.delete).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
        it('should call notification alert when some of selected number types are in use', function() {
            var c = controller();
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
                    hasError: true,
                    message: 'number type in use',
                    inUseIds: [1]
                }
            };

            spyOn(numberTypesService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(numberTypesService, 'markInUseNumberTypes');
            spyOn(c, 'search').and.callFake(function() {
                return {
                    then: function(cb) {
                        return cb();
                    }
                };
            });

            var expected = {
                title: 'modal.partialComplete',
                message: 'modal.alert.partialComplete<br/>modal.alert.alreadyInUse'
            };

            c.deleteSelectedNumberTypes();

            expect(numberTypesService.delete).toHaveBeenCalled();
            expect(numberTypesService.markInUseNumberTypes).toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });
        it('should call notification alert when all the selected number types are in use', function() {
            var c = controller();
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
                    hasError: true,
                    message: 'number type in use',
                    inUseIds: [1, 3]
                }
            };

            spyOn(numberTypesService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(numberTypesService, 'markInUseNumberTypes');
            spyOn(c, 'search').and.callFake(function() {
                return {
                    then: function(cb) {
                        return cb();
                    }
                };
            });

            var expected = {
                title: 'modal.unableToComplete',
                message: 'modal.alert.alreadyInUse'
            };

            c.deleteSelectedNumberTypes();

            expect(numberTypesService.delete).toHaveBeenCalled();
            expect(numberTypesService.markInUseNumberTypes).toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });
    });
});