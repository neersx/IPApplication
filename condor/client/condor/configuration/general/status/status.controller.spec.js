describe('inprotech.configuration.general.status.StatusController', function() {
    'use strict';

    var state, scope, controller, kendoGridBuilder, notificationService, modalService, statusService, translate;

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
        module('inprotech.configuration.general.status');
        module('inprotech.configuration.general.validcombination');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.general.status', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            statusService = $injector.get('StatusServiceMock');
            $provide.value('statusService', statusService);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);
        });
    });

    beforeEach(inject(function($state, $controller) {
        state = $state;

        controller = function(dependencies) {
            scope = {};
            dependencies = angular.extend({
                $scope: scope,
                supportData: {
                    stopPayReasons: [],
                    permissions: []
                },
                $state: state,
                $translate: translate
            }, dependencies);

            var c = $controller('StatusController', dependencies);
            c.$onInit();
            return c;
        };
    }));

    it('should initialise support data', function() {
        var c = controller();

        expect(c.supportData).toBeDefined();
        expect(c.supportData.stopPayReasons).toBeDefined();
        expect(c.supportData.permissions).toBeDefined();
    });


    it('should reset search criteria when controller is initialized', function() {
        var c = controller();

        expect(c.searchCriteria.text).toBe('');
    });

    it('should reset filter criteria when controller is initialized', function() {
        var c = controller();

        expect(c.filterCriteria.forCase).toBe(true);
        expect(c.filterCriteria.forRenewal).toBeDefined(false);
    });

    it('should set correct filter criteria when filter options are toggled', function() {
        var c = controller();

        c.toggleFilterOption('forRenewal');

        expect(c.filterCriteria.forCase).toBe(false);
        expect(c.filterCriteria.forRenewal).toBeDefined(true);
    });

    describe('add status', function() {
        it('should call modalService and entity state should be adding', function() {
            var c = controller();
            var entity = {
                statusType: 'case',
                statusSummary: 'pending',
                state: 'adding'
            };
            spyOn(statusService, 'add').and.returnValue(entity);
            c.addStatus();

            expect(modalService.openModal).toHaveBeenCalledWith(jasmine.objectContaining(_.extend({
                id: 'StatusMaintenance',
                controllerAs: 'vm',
                entity: entity,
                supportData: c.supportData
            })));
        });
    });

    describe('edit status', function() {
        it('should call modalService and entity state should be updating', function() {
            var c = controller();
            var entity = {
                id: 1,
                name: 'entity description',
                state: 'updating'
            };

            c.edit(1);

            expect(modalService.openModal).toHaveBeenCalledWith(jasmine.objectContaining(_.extend({
                id: 'StatusMaintenance',
                entity: entity,
                supportData: c.supportData,
                controllerAs: 'vm'
            })));
        });
    });
    describe('duplicate status', function() {
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
                id: 'StatusMaintenance',
                entity: {
                    id: null,
                    name: 'entity description - Copy',
                    state: 'duplicating'
                },
                supportData: c.supportData,
                controllerAs: 'vm'
            })));
        });
    });
    describe('delete status', function() {
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

            spyOn(statusService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });

            c.deleteSelectedStatus();

            expect(statusService.delete).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
        it('should call notification alert when some of selected status are in use', function() {
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
                    message: 'status in use',
                    inUseIds: [1]
                }
            };

            spyOn(statusService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(statusService, 'markInUseStatuses');

            var expected = {
                title: 'modal.partialComplete',
                message: translations['modal.alert.partialComplete'] + '<br/>' + translations['modal.alert.alreadyInUse']
            };

            c.deleteSelectedStatus();

            expect(statusService.delete).toHaveBeenCalled();
            expect(statusService.markInUseStatuses).toHaveBeenCalledWith(c.gridOptions.data(), response.data.inUseIds);
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });

        it('should call notification alert when all the selected status are in use', function() {
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
                    message: 'status in use',
                    inUseIds: [1, 3]
                }
            };

            spyOn(statusService, 'delete').and.callFake(function() {
                return {
                    then: function(fn) {
                        fn(response);
                    }
                };
            });
            spyOn(statusService, 'markInUseStatuses');

            var expected = {
                title: 'modal.unableToComplete',
                message: translations['modal.alert.alreadyInUse']
            };

            c.deleteSelectedStatus();

            expect(statusService.delete).toHaveBeenCalled();
            expect(statusService.markInUseStatuses).toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalledWith(expected);
        });
    });

    describe('valid status', function() {
        it('should call status service and state.go should have been called with provided state name and entity ', function() {
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
                    selected: false
                }];
            };

            spyOn(state, 'go');

            c.maintainValidCombination();

            expect(state.go).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalledWith('validcombination.status', {
                'status': _.first(c.gridOptions.data())
            });
        });
    });
});
