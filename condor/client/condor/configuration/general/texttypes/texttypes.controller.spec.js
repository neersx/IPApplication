describe('inprotech.configuration.general.texttypes.textTypesController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, notificationService, modalService, textTypesService;

    beforeEach(function() {
        module('inprotech.configuration.general.texttypes');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.general.texttypes', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            textTypesService = $injector.get('TextTypeServiceMock');
            $provide.value('textTypesService', textTypesService);

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

            var c = $controller('textTypesController', dependencies);
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
            expect(c.context).toBe('texttypes');
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

            textTypesService.search = jasmine.createSpy().and.callFake(function() {
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

            textTypesService.search = jasmine.createSpy().and.callFake(function() {
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
    describe('add text type', function() {
        it('should call modalService and entity state should be adding', function() {
            var c = controller();
            c.add();

            var entity = {
                usedByName: false,
                state: "adding"
            };
            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'TextTypeMaintenance',
                    controllerAs: 'vm',
                    entity: entity,
                    allItems: c.gridOptions.data(),
                    dataItem: getElementById(c.gridOptions.data(), entity.id)
                })));
            expect(scope.entity.state).toBe('adding');
        });
        it('should set usedByName to false', function() {
            var c = controller();
            c.add();

            expect(scope.entity.usedByName).toBe(false);
        });
    });
    describe('edit text type', function() {
        it('should not be available if no record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 'A'
                }, {
                    id: 'B'
                }];
            };
            expect(getElementById(c.textTypes, 'edit').enabled()).toBe(false);
        });
        it('should be available if record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 'A',
                    selected: true
                }, {
                    id: 'B'
                }];
            };
            expect(getElementById(c.textTypes, 'edit').enabled()).toBe(true);
        });
        it('should call modalService and entity state should be updating', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 'A',
                    selected: true
                }, {
                    id: 'B'
                }];
            };

            var entity = {
                id: 'A',
                state: "updating"
            };

            c.edit('A');

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'TextTypeMaintenance',
                    controllerAs: 'vm',
                    entity: entity,
                    allItems: c.gridOptions.data(),
                    dataItem: getElementById(c.gridOptions.data(), entity.id)
                })));
            expect(scope.entity.id).toBe(entity.id);
            expect(scope.entity.state).toBe('updating');
        });
    });
    describe('duplicate text type', function() {
        it('should not be available if no record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 'A'
                }, {
                    id: 'B'
                }];
            };
            expect(getElementById(c.textTypes, 'duplicate').enabled()).toBe(false);
        });
        it('should be available if record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 'A',
                    selected: true
                }, {
                    id: 'B'
                }];
            };
            expect(getElementById(c.textTypes, 'duplicate').enabled()).toBe(true);
        });
        it('should call modalService and entity state should be duplicating', function() {
            var c = controller();
            var entity = {
                id: null,
                state: "duplicating"
            };
            c.gridOptions.data = function() {
                return [{
                    id: 'A',
                    selected: true
                }, {
                    id: 'B'
                }];
            };

            c.duplicate();
            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'TextTypeMaintenance',
                    controllerAs: 'vm',
                    entity: entity,
                    allItems: c.gridOptions.data(),
                    dataItem: getElementById(c.gridOptions.data(), entity.id)
                })));
            expect(scope.entity.state).toBe('duplicating');
        });
    });
    describe('delete text types', function() {
        it('should call notification success and should initialize the grid', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 'A',
                    selected: true
                }, {
                    id: 'B',
                    selected: false
                }, {
                    id: 'C',
                    selected: true
                }];
            };

            var response = {
                data: {
                    message: 'deleted'
                }
            };

            spyOn(textTypesService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(c, 'search');

            c.deleteSelectedTextTypes();

            expect(textTypesService.delete).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.search).toHaveBeenCalled();
        });
        it('should call notification alert when some of selected text types are in use', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 'A',
                    selected: true
                }, {
                    id: 'B',
                    selected: false
                }, {
                    id: 'C',
                    selected: true
                }];
            };
            var response = {
                data: {
                    hasError: true,
                    message: 'number type in use',
                    inUseIds: ['A']
                }
            };

            spyOn(textTypesService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(textTypesService, 'markInUseTextTypes');
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

            c.deleteSelectedTextTypes();

            expect(textTypesService.delete).toHaveBeenCalled();
            expect(textTypesService.markInUseTextTypes).toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });
        it('should call notification alert when all the selected text types are in use', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 'A',
                    selected: true
                }, {
                    id: 'B',
                    selected: false
                }, {
                    id: 'C',
                    selected: true
                }];
            };
            var response = {
                data: {
                    hasError: true,
                    message: 'text type in use',
                    inUseIds: ['A', 'C']
                }
            };

            spyOn(textTypesService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(textTypesService, 'markInUseTextTypes');
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

            c.deleteSelectedTextTypes();

            expect(textTypesService.delete).toHaveBeenCalled();
            expect(textTypesService.markInUseTextTypes).toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });
    });
    describe('change text type', function() {
        it('should call modalService', function() {
            var c = controller();

            c.gridOptions.data = function() {
                return [{
                    id: 'A',
                    selected: true
                }, {
                    id: 'B'
                }];
            };

            c.changeTextTypeCode();

            var entity = {
                id: 'A',
                newTextTypeCode: null
            };
            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'ChangeTextTypeCode',                    
                    entity: entity,
                    controllerAs: 'vm'
                })));
        });
    });
});
