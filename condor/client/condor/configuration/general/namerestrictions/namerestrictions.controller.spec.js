describe('inprotech.configuration.general.namerestrictions.NameRestrictionsController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, notificationService, modalService, nameRestrictionsService, translate;

    var translations = {
        'modal.alert.partialComplete': 'This process has been partially completed.',
        'modal.alert.alreadyInUse': 'Items highlighted in red cannot be deleted as they are in use.',
        'modal.confirmation.copy': 'Copy'
    };


    translate = function(translation) {
        return {
            then: function(callback) {
                var translated = {};

                if (!angular.isArray(translation)) {
                    translated = translations[translation];
                } else {
                    translation.map(function(transl) {
                        translated[transl] = translations[transl];
                    });
                }

                return callback(translated);
            }
        };
    };

    beforeEach(function() {
        module('inprotech.configuration.general.namerestrictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.general.namerestrictions', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            nameRestrictionsService = $injector.get('NameRestrictionsServiceMock');
            $provide.value('nameRestrictionsService', nameRestrictionsService);

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
                viewData: {},
                $translate: translate
            }, dependencies);

            var c = $controller('NameRestrictionsController', dependencies);
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
            expect(c.context).toBe('namerestrictions');
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

            nameRestrictionsService.search = jasmine.createSpy().and.callFake(function() {
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

            nameRestrictionsService.search = jasmine.createSpy().and.callFake(function() {
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
    describe('add name restriction', function() {
        it('should call modalService and entity state should be adding', function() {
            var c = controller();
            c.add();

            var entity = {
                state: "adding"
            };
            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'NameRestrictionsMaintenance',
                    controllerAs: 'vm',
                    entity: entity,
                    viewData: c.viewData,
                    allItems: c.gridOptions.data(),
                    dataItem: getElementById(c.gridOptions.data(), entity.id)
                })));
        });
    });
    describe('edit name restriction', function() {
        it('should not be available if no record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 1
                }, {
                    id: 2
                }];
            };
            expect(getElementById(c.nameRestrictions, 'edit').enabled()).toBe(false);
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
            expect(getElementById(c.nameRestrictions, 'edit').enabled()).toBe(true);
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
                state: "updating",
                description: 'entity description'
            };

            c.edit(1);

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'NameRestrictionsMaintenance',
                    controllerAs: 'vm',
                    entity: entity,
                    allItems: c.gridOptions.data(),
                    dataItem: getElementById(c.gridOptions.data(), entity.id)
                })));
        });
    });
    describe('duplicate name restriction', function() {
        it('should not be available if no record is selected', function() {
            var c = controller();
            c.gridOptions.data = function() {
                return [{
                    id: 1
                }, {
                    id: 2
                }];
            };
            expect(getElementById(c.nameRestrictions, 'duplicate').enabled()).toBe(false);
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
            expect(getElementById(c.nameRestrictions, 'duplicate').enabled()).toBe(true);
        });
        it('should call modalService and entity state should be duplicating', function() {
            var c = controller();
            var expectedEntity = {
                id: null,
                state: "duplicating",
                description: 'entity description - Copy'
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
                    id: 'NameRestrictionsMaintenance',
                    controllerAs: 'vm',
                    entity: expectedEntity,
                    allItems: c.gridOptions.data(),
                    dataItem: getElementById(c.gridOptions.data(), expectedEntity.id)
                })));
        });
    });
    describe('delete name restriction', function() {
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

            spyOn(nameRestrictionsService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });

            c.deleteSelectedNameRestrictions();

            expect(nameRestrictionsService.delete).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
        it('should call notification alert when some of selected name restrictions are in use', function() {
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
                    message: 'name restriction in use',
                    inUseIds: [1]
                }
            };

            spyOn(nameRestrictionsService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(nameRestrictionsService, 'markInUseNameRestrictions');

            var expected = {
                title: 'modal.partialComplete',
                message: translations['modal.alert.partialComplete'] + '<br/>' + translations['modal.alert.alreadyInUse']
            };

            c.deleteSelectedNameRestrictions();

            expect(nameRestrictionsService.delete).toHaveBeenCalled();
            expect(nameRestrictionsService.markInUseNameRestrictions).toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });
        it('should call notification alert when all the selected name restrictions are in use', function() {
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
                    message: 'name restriction in use',
                    inUseIds: [1, 3]
                }
            };

            spyOn(nameRestrictionsService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(nameRestrictionsService, 'markInUseNameRestrictions');

            var expected = {
                title: 'modal.unableToComplete',
                message: translations['modal.alert.alreadyInUse']
            };

            c.deleteSelectedNameRestrictions();

            expect(nameRestrictionsService.delete).toHaveBeenCalled();
            expect(nameRestrictionsService.markInUseNameRestrictions).toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });
    });
});