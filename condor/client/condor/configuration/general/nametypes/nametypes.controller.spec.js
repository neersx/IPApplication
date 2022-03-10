describe('inprotech.configuration.general.nametypes.NameTypesController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, notificationService, modalService, nameTypesService;

    beforeEach(function() {
        module('inprotech.configuration.general.nametypes');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.general.nametypes', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            nameTypesService = $injector.get('NameTypeServiceMock');
            $provide.value('nameTypesService', nameTypesService);

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

            var c = $controller('NameTypesController', dependencies);
            c.$onInit();
            return c;
        };
    }));

    function bulkActionMenuItem(items, name) {
        return _.find(items, function(item) {
            return item.id === name;
        });
    }

    describe('initialize view model', function() {
        it('should initialize grid builder options along with search criteria', function() {
            var c = controller();

            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.context).toBe('nametypes');
            expect(c.searchCriteria.text).toBe('');
            expect(c.searchCriteria.nameTypeGroup).toBeNull();
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

            nameTypesService.search = jasmine.createSpy().and.callFake(function() {
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

            c.gridOptions.search();

            expect(c.gridOptions.data().length).toBe(2);
        });
        it('should initialize grid data', function() {
            var c = controller();
            var response = {
                data: []
            };

            nameTypesService.search = jasmine.createSpy().and.callFake(function() {
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

    describe('add name type', function() {
        it('should call modalService and entity state should be adding', function() {
            var c = controller();
            var entity = {
                state: 'adding',
                minAllowedForCase: '0',
                displayNameCode: 'none',
                ethicalWallOption: 'notApplicable'
            };
            spyOn(nameTypesService, 'add').and.returnValue(entity);

            c.add();

            expect(modalService.openModal).toHaveBeenCalledWith(jasmine.objectContaining(_.extend({
                id: 'NameTypeMaintenance',
                controllerAs: 'vm',
                entity: entity
            })));
        });
    });

    describe('edit name type', function() {
        it('should not be available if no record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 1
                }, {
                    id: 2
                }];
            };
            expect(bulkActionMenuItem(c.actions, 'edit').enabled()).toBe(false);
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
            expect(bulkActionMenuItem(c.actions, 'edit').enabled()).toBe(true);
        });
        it('should call modalService and entity state should be updating', function() {
            var c = controller();
            var entity = {
                id: 1,
                state: 'updating'
            };

            c.edit(1);

            expect(modalService.openModal).toHaveBeenCalledWith(jasmine.objectContaining(_.extend({
                id: 'NameTypeMaintenance',
                controllerAs: 'vm',
                entity: entity
            })));
        });
    });
    describe('duplicate name type', function() {
        it('should not be available if no record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 1
                }, {
                    id: 2
                }];
            };
            expect(bulkActionMenuItem(c.actions, 'duplicate').enabled()).toBe(false);
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
            expect(bulkActionMenuItem(c.actions, 'duplicate').enabled()).toBe(true);
        });
        it('should call modalService and entity state should be duplicating', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 1,
                    selected: true
                }, {
                    id: 2
                }];
            };

            c.duplicate();

            expect(modalService.openModal).toHaveBeenCalledWith(jasmine.objectContaining(_.extend({
                id: 'NameTypeMaintenance',
                controllerAs: 'vm',
                entity: {
                    id: null,
                    state: 'duplicating'
                }
            })));
        });
    });
    describe('delete name types', function() {
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

            spyOn(nameTypesService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });

            c.deleteSelectedNameTypes();

            expect(nameTypesService.delete).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
        it('should call notification alert when some of selected name types are in use', function() {
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
                    message: 'name type in use',
                    inUseIds: [1]
                }
            };

            spyOn(nameTypesService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(nameTypesService, 'markInUseNameTypes');

            var expected = {
                title: 'modal.partialComplete',
                message: 'modal.alert.partialComplete<br/>modal.alert.alreadyInUse'
            };

            c.deleteSelectedNameTypes();

            expect(nameTypesService.delete).toHaveBeenCalled();
            expect(nameTypesService.markInUseNameTypes).toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });
        it('should call notification alert when all the selected name types are in use', function() {
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
                    message: 'name type in use',
                    inUseIds: [1, 3]
                }
            };

            spyOn(nameTypesService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(nameTypesService, 'markInUseNameTypes');

            var expected = {
                title: 'modal.unableToComplete',
                message: 'modal.alert.alreadyInUse'
            };

            c.deleteSelectedNameTypes();

            expect(nameTypesService.delete).toHaveBeenCalled();
            expect(nameTypesService.markInUseNameTypes).toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });
    });
    it('should open priority window modal instance on priority link', function() {
        var c = controller();
        c.launchNameTypesPriorityOrder();

        expect(modalService.openModal).toHaveBeenCalledWith(jasmine.objectContaining(_.extend({
            launchSrc: 'search',
            id: 'NameTypesOrder',
            controllerAs: 'vm'
        })));

    });
    describe('set font weight to bold if Name group that is filtered is the current name group', function() {
        it('should return bold if the Name group is the same as that is filtered', function() {
            var c = controller();
            c.searchCriteria.nameTypeGroup = [{
                    key: 1
                }, {
                    key: 2
                }];
            var nameTypeGroup = {
                id: 1
            }
            expect(c.highlightFilteredNameGroup(nameTypeGroup)).toBe('bold');
        });
        it('should return null if the Name group is the same as that is filtered', function() {
            var c = controller();
            c.searchCriteria.nameTypeGroup = [{
                    key: 1
                }, {
                    key: 2
                }];
            var nameTypeGroup = {
                id: 3
            }
            expect(c.highlightFilteredNameGroup(nameTypeGroup)).toBe(undefined);
        });
    });
});