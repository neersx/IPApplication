describe('inprotech.picklists.eventsController', function() {
    'use strict';

    var controller, http, scope, extObjFactory, modalService;

    beforeEach(module('inprotech.picklists'));
    beforeEach(inject(function($httpBackend, $rootScope, $controller) {
        var $injector = angular.injector(['inprotech.core.extensible', 'inprotech.mocks']);
        extObjFactory = $injector.get('ExtObjFactory');
        modalService = $injector.get('modalServiceMock');

        http = $httpBackend;
        scope = $rootScope.$new();

        controller = function(newScope) {
            if (newScope) {
                scope = angular.extend(scope, newScope);
            } else {
                scope = angular.extend(scope, {
                    vm: {
                        maintenanceState: "viewing",
                        entry: {
                            clientImportance: null,
                            internalImportance: null
                        }
                    }
                });
            }
            scope.vm.maintenance = {
                $setDirty: function() {
                    return;
                }
            };
            scope.vm.saveWithoutValidate = function() {
                return;
            };

            spyOn(scope.vm.maintenance, '$setDirty').and.callThrough();
            spyOn(scope.vm, 'saveWithoutValidate').and.callThrough();

            var dependencies = {
                $scope: scope,
                ExtObjFactory: extObjFactory,
                modalService: modalService
            };

            return $controller('eventsController', dependencies);
        };

    }));

    describe('initialising', function() {
        it('should initialise defaults and get support data', function() {
            var supportData = [];
            http.whenGET('api/picklists/events/supportdata')
                .respond(function() {
                    return [200, supportData, {}];
                });

            var ctr = controller();
            http.flush();

            expect(ctr.supportData).toEqual(supportData);
            expect(ctr.canEnterMaxCycles).toEqual(true);
            expect(ctr.formData).toBeDefined();
            expect(ctr.isReadOnly).toEqual(true);
        });
    });

    describe('editing an event', function() {
        it('should initialise defaults', function() {
            var supportData = [];
            http.whenGET('api/picklists/events/supportdata')
                .respond(function() {
                    return [200, supportData, {}];
                });

            var ctr = controller({
                vm: {
                    maintenanceState: "updating",
                    entry: {
                        clientImportance: null,
                        internalImportance: null,
                        hasUpdatableCriteria: false
                    }
                }
            });
            http.flush();

            expect(ctr.supportData).toEqual(supportData);
            expect(ctr.canEnterMaxCycles).toEqual(true);
            expect(ctr.formData).toBeDefined();
            expect(ctr.isReadOnly).toEqual(false);
            expect(scope.vm.onBeforeSave).toBe(null);
            expect(ctr.hasPropagatableChanges).toBe(false);
        });
        it('should set onBeforeSave handler where required', function() {
            var supportData = [];
            http.whenGET('api/picklists/events/supportdata')
                .respond(function() {
                    return [200, supportData, {}];
                });

            var ctr = controller({
                vm: {
                    maintenanceState: "updating",
                    entry: {
                        clientImportance: null,
                        internalImportance: null,
                        hasUpdatableCriteria: true
                    }
                }
            });
            http.flush();

            expect(ctr.supportData).toEqual(supportData);
            expect(ctr.canEnterMaxCycles).toEqual(true);
            expect(ctr.formData).toBeDefined();
            expect(ctr.isReadOnly).toEqual(false);
            expect(scope.vm.onBeforeSave).toBeDefined();
            expect(ctr.hasPropagatableChanges).toBe(false);
        });
    });

    describe('copying an event', function() {
        it('should initialise defaults', function() {
            var supportData = [];
            http.whenGET('api/picklists/events/supportdata')
                .respond(function() {
                    return [200, supportData, {}];
                });

            var ctr = controller({
                vm: {
                    maintenanceState: "duplicating",
                    entry: {
                        description: "Event 101",
                        clientImportance: null,
                        internalImportance: null
                    }
                }
            });
            http.flush();

            expect(ctr.supportData).toEqual(supportData);
            expect(ctr.canEnterMaxCycles).toEqual(true);
            expect(ctr.formData).toBeDefined();
            expect(ctr.isReadOnly).toEqual(false);
            expect(ctr.formData.description).toEqual('Event 101 - Copy');
            expect(scope.vm.maintenance.$setDirty).toHaveBeenCalled();
        });
    });

    describe('adding a new event', function() {
        beforeEach(function() {
            var supportData = {
                defaultImportanceLevel: "3",
                defaultMaxCycles: "1"
            };
            http.whenGET('api/picklists/events/supportdata')
                .respond(function() {
                    return [200, supportData, {}];
                });
        })
        it('should initialise defaults', function() {
            var ctr = controller({
                vm: {
                    maintenanceState: "adding",
                    entry: {
                        clientImportance: null,
                        internalImportance: null
                    }
                }
            });
            http.flush();
            scope.$digest();
            expect(ctr.formData.clientImportance).toEqual("3");
            expect(ctr.formData.internalImportance).toEqual("3");
            expect(ctr.formData.maxCycles).toEqual("1");
            expect(ctr.formData.unlimitedCycles).toEqual(false);
            expect(ctr.formData.description).toEqual('');
            expect(ctr.formData.code).toEqual('');
            expect(ctr.formData.notes).toEqual('');
            expect(ctr.formData.category).toEqual(null);
            expect(ctr.formData.group).toEqual('');
            expect(ctr.formData.controllingAction).toEqual(null);
            expect(ctr.formData.draftCaseEvent).toEqual(null);
            expect(ctr.formData.isAccountingEvent).toEqual(false);
            expect(ctr.formData.recalcEventDate).toEqual(false);
            expect(ctr.formData.allowPoliceImmediate).toEqual(false);
            expect(ctr.formData.suppressCalculation).toEqual(false);
            expect(ctr.formData.notesGroup).toEqual('');
            expect(ctr.formData.notesSharedAcrossCycles).toEqual(false);
            expect(ctr.isEventNumberVisible).toBe(false);
            expect(ctr.isReadOnly).toEqual(false);
            expect(scope.vm.maintenance.$setDirty).not.toHaveBeenCalled();
        });
        it('should set description to search value and dirty', function() {
            var ctr = controller({
                vm: {
                    maintenanceState: "adding",
                    entry: {},
                    searchValue: "Initial filing"
                }
            });
            http.flush();
            scope.$digest();
            expect(ctr.formData.description).toEqual("Initial filing");
            expect(scope.vm.maintenance.$setDirty).toHaveBeenCalled();
        });
    });

    describe('when', function() {
        beforeEach(function() {
            var supportData = [];
            http.whenGET('api/picklists/events/supportdata')
                .respond(function() {
                    return [200, supportData, {}];
                });
        });
        describe('setting importance level', function() {
            it('should leave client importance if already specified', function() {
                var ctr = controller({
                    vm: {
                        entry: {
                            clientImportance: 1,
                            internalImportance: 9
                        }
                    }
                });
                scope.$digest();
                ctr.setClientImportance()
                expect(ctr.formData.clientImportance).toEqual(1);
                expect(ctr.formData.internalImportance).toEqual(9);
            });
            it('should default client importance if none specified', function() {
                var ctr = controller({
                    vm: {
                        entry: {
                            clientImportance: null,
                            internalImportance: 9
                        }
                    }
                });
                scope.$digest();
                ctr.setClientImportance()
                expect(ctr.formData.clientImportance).toEqual(9);
                expect(ctr.formData.internalImportance).toEqual(9);
            });
        });

        describe('toggling unlimited cycles', function() {
            it('should set maxCycles to 9999 and disable the field when checked', function() {
                var ctr = controller({
                    vm: {
                        entry: {
                            maxCycles: 1,
                            unlimitedCycles: false
                        }
                    }
                });
                scope.$digest();
                ctr.toggleMaxCycle({
                    target: {
                        checked: true
                    }
                });
                expect(ctr.formData.maxCycles).toEqual(9999);
                expect(ctr.canEnterMaxCycles).toEqual(false);
            });
            it('should enable maxCycles when unchecked', function() {
                var ctr = controller({
                    vm: {
                        entry: {
                            maxCycles: 9999,
                            unlimitedCycles: true
                        }
                    }
                });
                scope.$digest();
                ctr.toggleMaxCycle({
                    target: {
                        checked: false
                    }
                });
                expect(ctr.formData.maxCycles).toEqual(9999);
                expect(ctr.canEnterMaxCycles).toEqual(true);
            });
        });
    });
    describe('onBeforeSave', function() {
        var ctr;
        beforeEach(function() {
            var supportData = [];
            http.whenGET('api/picklists/events/supportdata')
                .respond(function() {
                    return [200, supportData, {}];
                });

            ctr = controller({
                vm: {
                    maintenanceState: "updating",
                    entry: {
                        clientImportance: null,
                        internalImportance: 9,
                        maxCycles: 1,
                        unlimitedCycles: false,
                        description: "12345",
                        recalcEventDate: false,
                        suppressCalculation: false,
                        code: "",
                        notes: ""
                    }
                }
            });
            http.flush();
            scope.$digest();
        });
        it('should proceed with the save if there are no changes', function() {
            ctr.onBeforeSave();
            expect(scope.vm.saveWithoutValidate).toHaveBeenCalled();
            expect(modalService.open).not.toHaveBeenCalled();
        });
        it('should not display dialog if there are no applicable changes', function() {
            ctr.formData.code = "abcd";
            ctr.formData.notes = "abcd";
            scope.$digest();
            ctr.onBeforeSave();
            expect(scope.vm.saveWithoutValidate).toHaveBeenCalled();
            expect(modalService.open).not.toHaveBeenCalled();
        });
        it('should proceed with the save if there are no applicable Description changes', function() {
            ctr.formData.description = "abcd";
            scope.$digest();
            ctr.onBeforeSave();
            expect(scope.vm.saveWithoutValidate).toHaveBeenCalled();
            expect(modalService.open).not.toHaveBeenCalled();
        });
        it('should display confirmation dialog if there are applicable Description changes', function() {
            scope.vm.entry.isDescriptionUpdatable = true;
            ctr.formData.description = "abcd";
            scope.$digest();
            ctr.onBeforeSave();
            expect(modalService.open).toHaveBeenCalled();
            expect(scope.vm.saveWithoutValidate).not.toHaveBeenCalled();
        });
        it('should display confirmation dialog if there are applicable MaxCycle changes', function() {
            ctr.formData.maxCycles = 999;
            scope.$digest();
            ctr.onBeforeSave();
            expect(modalService.open).toHaveBeenCalled();
        });
        it('should display confirmation dialog if there are applicable Importance Level changes', function() {
            ctr.formData.internalImportance = "3";
            scope.$digest();
            ctr.onBeforeSave();
            expect(modalService.open).toHaveBeenCalled();
        });
        it('should display confirmation dialog if there are applicable Recalc Event Date changes', function() {
            ctr.formData.recalcEventDate = true;
            scope.$digest();
            ctr.onBeforeSave();
            expect(modalService.open).toHaveBeenCalled();
        });
        it('should display confirmation dialog if there are applicable Suppress Due Date Recalc changes', function() {
            ctr.formData.suppressCalculation = true;
            scope.$digest();
            ctr.onBeforeSave();
            expect(modalService.open).toHaveBeenCalled();
        });
    });

});