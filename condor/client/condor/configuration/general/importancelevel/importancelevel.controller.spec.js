describe('inprotech.configuration.general.importancelevel.ImportanceLevelController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, notificationService, importanceLevelService, workflowsEntryControlService;

    beforeEach(function() {
        module('inprotech.configuration.general.importancelevel');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.general.importancelevel', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            importanceLevelService = $injector.get('ImportanceLevelServiceMock');
            $provide.value('importanceLevelService', importanceLevelService);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            workflowsEntryControlService = test.mock('workflowsEntryControlService');
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            scope = {};
            dependencies = angular.extend({
                $scope: scope,
                viewData: {}
            }, dependencies);

            return $controller('ImportanceLevelController', dependencies);
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables correctly', function() {
            var c = controller();
            c.$onInit();

            expect(c.gridOptions).toBeDefined();
            expect(c.onAddClick).toBeDefined();
            expect(c.checkLevelDuplicate).toBeDefined();
            expect(c.checkDescriptionDuplicate).toBeDefined();
            expect(c.isSaveEnabled).toBeDefined();
            expect(c.isDiscardEnabled).toBeDefined();
            expect(c.discard).toBeDefined();
            expect(c.save).toBeDefined();
            expect(c.onLevelChanged).toBeDefined();
            expect(c.onDescriptionChanged).toBeDefined();
        });
    });

    describe('initialize', function() {
        it('should initialize grid data', function() {
            var c = controller();
            c.$onInit();
            var response = {
                data: [{
                    level: '1'
                }, {
                    level: '2'
                }]
            };

            importanceLevelService.search = jasmine.createSpy().and.callFake(function() {
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
            c.$onInit();
            var response = {
                data: []
            };

            importanceLevelService.search = jasmine.createSpy().and.callFake(function() {
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

    describe('On Add Click', function() {
        it('should add an item to the end of the grid', function() {
            var c = controller();
            c.$onInit();
            var totalSpy = jasmine.createSpy().and.returnValue(99);
            c.gridOptions.dataSource = {
                total: totalSpy
            };
            c.onAddClick();
            expect(c.gridOptions.insertRow).toHaveBeenCalledWith(99, jasmine.objectContaining({
                added: true
            }));
        });

    });

    describe('on row edit', function() {
        var rowForm, item;
        beforeEach(function() {
            rowForm = {
                description: {
                    '$setValidity': jasmine.createSpy()
                },
                level: {
                    '$setValidity': jasmine.createSpy()
                }
            };

            item = {
                isEdited: false,
                inUse: false,
                error: false
            };
        });

        it('marks rows as isEdited', function() {
            var c = controller();
            c.$onInit();

            c.gridOptions.dataSource.data = jasmine.createSpy().and.returnValue([item]);

            c.onDescriptionChanged(item, rowForm);

            expect(item.isEdited).toBe(true);
            expect(item.inUse).toBe(false);
            expect(item.error).toBe(false);
            expect(rowForm.description.$setValidity).toHaveBeenCalledWith('duplicate', true);
        });

        it('checks for duplicate description on description changed', function() {

            var c = controller();
            c.$onInit();
            c.gridOptions.dataSource.data = function() {
                return [{
                    level: '1',
                    description: 'level 1'
                }, {
                    level: '2',
                    description: 'level 2'
                }, {
                    level: '3',
                    description: 'level 2'
                }];
            };

            var dataItem = c.gridOptions.dataSource.data()[2];

            workflowsEntryControlService.isDuplicated = jasmine.createSpy().and.returnValue(true);

            c.onDescriptionChanged(dataItem, rowForm);

            expect(rowForm.description.$setValidity).toHaveBeenCalledWith('duplicate', false);
            expect(dataItem.duplicatedFields.length > 0).toBe(true);
            expect(_.first(dataItem.duplicatedFields)).toBe('description');
        });

        it('checks for duplicate description', function() {

            var c = controller();
            c.$onInit();
            c.gridOptions.dataSource.data = function() {
                return [{
                    level: '1',
                    description: 'level 1'
                }, {
                    level: '2',
                    description: 'level 2'
                }, {
                    level: '3',
                    description: 'level 2'
                }];
            };

            var dataItem = c.gridOptions.dataSource.data();
            dataItem.duplicatedFields = [];
            dataItem.duplicatedFields.push('description');

            c.checkDescriptionDuplicate(dataItem, rowForm);

            expect(rowForm.description.$setValidity).toHaveBeenCalledWith('duplicate', false);
        });

        it('checks for duplicate level on level changed', function() {

            var c = controller();
            c.$onInit();
            c.gridOptions.dataSource.data = function() {
                return [{
                    level: '1',
                    description: 'level 1'
                }, {
                    level: '2',
                    description: 'level 2'
                }, {
                    level: '1',
                    description: 'level 3'
                }];
            };

            var dataItem = c.gridOptions.dataSource.data()[2];

            workflowsEntryControlService.isDuplicated = jasmine.createSpy().and.returnValue(true);

            c.onLevelChanged(dataItem, rowForm);

            expect(rowForm.level.$setValidity).toHaveBeenCalledWith('duplicate', false);
            expect(dataItem.duplicatedFields.length > 0).toBe(true);
            expect(_.first(dataItem.duplicatedFields)).toBe('level');
        });

        it('checks for duplicate level', function() {

            var c = controller();
            c.$onInit();
            c.gridOptions.dataSource.data = function() {
                return [{
                    level: '1',
                    description: 'level 1'
                }, {
                    level: '2',
                    description: 'level 2'
                }, {
                    level: '1',
                    description: 'level 3'
                }];
            };

            var dataItem = c.gridOptions.dataSource.data();
            dataItem.duplicatedFields = [];
            dataItem.duplicatedFields.push('level');

            c.checkLevelDuplicate(dataItem, rowForm);

            expect(rowForm.level.$setValidity).toHaveBeenCalledWith('duplicate', false);
        });

    });

    describe('On Save Click', function() {
        it('should add an item to the grid', function() {
            var c = controller();
            c.$onInit();
            c.form = {
                $validate: _.constant(true)
            };

            c.gridOptions.dataSource.data = function() {
                return [{
                    level: '1',
                    description: 'level 1',
                    added: true
                }, {
                    level: '2',
                    description: 'level 2'
                }, {
                    level: '3',
                    description: 'level 3'
                }];
            };

            importanceLevelService.save = jasmine.createSpy().and.callFake(function() {
                return {
                    then: function(cb) {
                        var response = {
                            data: {
                                result: 'success'
                            }
                        };
                        return cb(response);
                    }
                };
            });

            c.save();

            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();

        });

        it('should return isSaveEnabled true', function() {
            var c = controller();
            c.$onInit();
            c.form = {
                $validate: _.constant(true)
            };

            c.gridOptions.dataSource.data = function() {
                return [{
                    level: '1',
                    description: 'level 1',
                    added: true
                }, {
                    level: '2',
                    description: 'level 2'
                }];
            };
            expect(c.isSaveEnabled()).toBe(true);
        });

        it('should return isSaveEnabled false', function() {
            var c = controller();
            c.$onInit();
            c.gridOptions.dataSource.data = function() {
                return [{
                    level: '1',
                    description: 'level 1'
                }, {
                    level: '2',
                    description: 'level 2'
                }];
            };
            expect(c.isSaveEnabled()).toBe(false);
        });

        it('should return isDiscardEnabled ture', function() {
            var c = controller();
            c.$onInit();
            c.gridOptions.dataSource.data = function() {
                return [{
                    level: '1',
                    description: 'level 1',
                    added: true
                }, {
                    level: '2',
                    description: 'level 2'
                }];
            };
            expect(c.isDiscardEnabled()).toBe(true);
        });

        it('should return isDiscardEnabled false', function() {
            var c = controller();
            c.$onInit();
            c.gridOptions.dataSource.data = function() {
                return [{
                    level: '1',
                    description: 'level 1'
                }, {
                    level: '2',
                    description: 'level 2'
                }];
            };
            expect(c.isDiscardEnabled()).toBe(false);
        });

        it('should invoke notification service when item deleted is in use', function() {
            var c = controller();
            c.$onInit();
            c.form = {
                $validate: _.constant(true)
            };

            c.gridOptions.dataSource.data = function() {
                return [{
                    level: '1',
                    description: 'level 1'
                }, {
                    level: '2',
                    description: 'level 2'
                }, {
                    level: '3',
                    description: 'level 3',
                    deleted: true
                }];
            };

            importanceLevelService.save = jasmine.createSpy().and.callFake(function() {
                return {
                    then: function(cb) {
                        var response = {
                            data: {
                                result: 'error',
                                validationErrors: [{
                                    operationType: 'deleting',
                                    inUseIds: ['3']
                                }]
                            }
                        };
                        return cb(response);
                    }
                };
            });

            var expected = {
                title: 'modal.unableToComplete',
                message: 'modal.alert.alreadyInUse'
            };

            c.save();

            expect(notificationService.alert).toHaveBeenCalledWith(expected);
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
        it('should invoke notification service when item added already exists', function() {
            var c = controller();
            c.$onInit();
            c.form = {
                $validate: _.constant(true)
            };

            var item1 = {
                level: '1',
                description: 'level 1'
            };

            var item2 = {
                level: '2',
                description: 'level 2'
            };

            var item3 = {
                level: '3',
                description: 'level 3'
            };

            var addedItem = {
                level: '1',
                description: 'level 4',
                added: true
            };

            c.gridOptions.dataSource.data = function() {
                return [item1, item2, item3, addedItem];
            };

            importanceLevelService.save = jasmine.createSpy().and.callFake(function() {
                return {
                    then: function(cb) {
                        var response = {
                            data: {
                                result: 'error',
                                validationErrors: [{
                                    id: '1',
                                    message: 'field.errors.notunique',
                                    field: 'level'
                                }]
                            }
                        };
                        return cb(response);
                    }
                };
            });

            c.save();

            expect(addedItem.error).toBe(true);
        });

    });

});