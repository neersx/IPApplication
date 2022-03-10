describe('DocumentsMaintenanceController', function() {
    'use strict';

    var scope, controller, modalInstance, workflowsEventControlService, maintModalService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module('inprotech.core');

        module(function() {
            modalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock');
            workflowsEventControlService = test.mock('workflowsEventControlService');
            maintModalService = test.mock('maintenanceModalService');
        });

        inject(function($rootScope, $controller) {
            scope = $rootScope.$new();
            scope.$emit = jasmine.createSpy();
            controller = function(options) {
                var ctrl = $controller('DocumentsMaintenanceController', {
                    $scope: scope,
                    options: _.extend({}, options)
                });

                return ctrl;
            };
        });
    });

    describe('initialisation', function() {
        it('should initialise vm', function() {
            var ctrl = controller({
                isAddAnother: 'isAddAnother',
                criteriaId: 'criteriaId',
                allItems: 'allItems',
                eventId: 'eventId',
                eventDescription: 'eventDescription',
                dataItem: {
                    abc: 'abc'
                }
            });

            expect(ctrl).toEqual(jasmine.objectContaining({
                isAddAnother: 'isAddAnother',
                criteriaId: 'criteriaId',
                allItems: 'allItems',
                eventId: 'eventId',
                eventDescription: 'eventDescription',
                currentItem: {
                    abc: 'abc'
                },
                formData: {
                    produce: 'eventOccurs',
                    abc: 'abc'
                },
                apply: jasmine.any(Function),
                onNavigate: jasmine.any(Function),
                isApplyEnabled: jasmine.any(Function),
                dismiss: jasmine.any(Function),
                hasUnsavedChanges: jasmine.any(Function),
                isScheduledDisabled: jasmine.any(Function),
                onProduceChange: jasmine.any(Function),
                onRecurringChange: jasmine.any(Function)
            }));
        });

        it('should initialises title for add mode', function() {
            var ctrl = controller({
                mode: 'add'
            });
            expect(ctrl.title).toBe('.addTitle');
            expect(ctrl.isEditMode).toBe(false);
        });

        it('should initialises title for edit mode', function() {
            var ctrl = controller({
                mode: 'edit'
            });
            expect(ctrl.title).toBe('.editTitle');
            expect(ctrl.isEditMode).toBe(true);
        });

        describe('should get correct recurring', function() {
            it('should enable recurring when repeatEvery has value', function() {
                var ctrl = controller({
                    dataItem: {
                        produce: 'asScheduled',
                        repeatEvery: 'abc'
                    }
                });

                expect(ctrl.recurring).toEqual(true);
            });

            it('should enable recurring when stopTime has value', function() {
                var ctrl = controller({
                    dataItem: {
                        produce: 'asScheduled',
                        stopTime: {
                            value: 'abc'
                        }
                    }
                });
                expect(ctrl.recurring).toEqual(true);
            });

            it('should disable recurring', function() {
                var ctrl = controller({});
                expect(ctrl.recurring).toEqual(false);
            });
        });

        it('extends formData defaults to populate from dataItem', function() {
            var ctrl = controller({
                mode: 'edit',
                dataItem: {
                    a: 'a',
                    b: 'b'
                }
            });

            expect(ctrl.formData).toEqual({
                a: 'a',
                b: 'b',
                produce: 'eventOccurs'
            });
        });
    });

    describe('isScheduledDisabled', function() {
        it('should return false', function() {
            var ctrl = controller({
                dataItem: {
                    produce: 'asScheduled'
                }
            });

            var result = ctrl.isScheduledDisabled();

            expect(result).toEqual(false);
        });

        it('should return true', function() {
            var ctrl = controller({
                dataItem: {
                    produce: 'whatever'
                }
            });

            var result = ctrl.isScheduledDisabled();

            expect(result).toEqual(true);
        });
    });

    describe('onProduceChange', function() {
        var ctrl;

        beforeEach(function() {
            ctrl = controller({
                recurring: true,
                dataItem: {
                    produce: 'asScheduled',
                    startBefore: 'whatever',
                    repeatEvery: 'whatever',
                    stopTime: 'whatever',
                    maxDocuments: 'whatever'
                }
            });
        });

        it('should do nothing', function() {
            ctrl.isScheduledDisabled = _.constant(false);

            ctrl.onProduceChange();

            expect(ctrl.recurring).toEqual(true);
            expect(ctrl.formData.startBefore).toEqual('whatever');
            expect(ctrl.formData.repeatEvery).toEqual('whatever');
            expect(ctrl.formData.stopTime).toEqual('whatever');
            expect(ctrl.formData.maxDocuments).toEqual('whatever');
        });

        it('should reset', function() {
            ctrl.isScheduledDisabled = _.constant(true);

            ctrl.onProduceChange();

            expect(ctrl.recurring).toEqual(false);
            expect(ctrl.formData.startBefore).toEqual(null);
            expect(ctrl.formData.repeatEvery).toEqual(null);
            expect(ctrl.formData.stopTime).toEqual(null);
            expect(ctrl.formData.maxDocuments).toEqual(null);
        });
    });

    describe('onRecurringChange', function() {
        it('should make repeatEvery and startBefore same', function() {
            var ctrl = controller({
                dataItem: {
                    repeatEvery: 'repeatEvery',
                    startBefore: 'startBefore'
                }
            });

            ctrl.onRecurringChange(true);
            expect(ctrl.formData.repeatEvery).toEqual(ctrl.formData.startBefore);
        });

        it('should clear repeatEvery and stopTime', function() {
            var ctrl = controller({
                dataItem: {
                    repeatEvery: 'repeatEvery',
                    stopTime: 'stopTime'
                }
            });
            ctrl.onRecurringChange(false);
            expect(ctrl.formData.repeatEvery).toEqual(null);
            expect(ctrl.formData.stopTime).toEqual(null);
            expect(ctrl.formData.maxDocuments).toEqual(null);
        });
    });

    describe('apply', function() {
        it('checks if form is valid', function() {
            var ctrl = controller();
            ctrl.form = {
                $validate: _.constant(false),
                $dirty: true
            };

            ctrl.apply();

            expect(workflowsEventControlService.setEditedAddedFlags).not.toHaveBeenCalled();
            expect(maintModalService().applyChanges).not.toHaveBeenCalled();
        });

        it('sets flags and calls apply method for add', function () {
            var data = { description: 'added' };
            var options = {
                mode: 'add',
                isAddAnother: true
            };

            var ctrl = controller(options);
            ctrl.formData = data;
            ctrl.form = {
                $validate: _.constant(true)
            };

            ctrl.apply();

            expect(workflowsEventControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(data), false)

            expect(maintModalService().applyChanges).toHaveBeenCalledWith(jasmine.objectContaining(data), jasmine.objectContaining(options), false, true, undefined);
        });

        it('sets flags and calls apply method for edit', function () {
            var data = { description: 'edited' };
            var options = {
                mode: 'edit',
                isAddAnother: false
            };

            var ctrl = controller(options);
            ctrl.formData = data;
            ctrl.form = {
                $validate: _.constant(true)
            };

            ctrl.apply();

            expect(workflowsEventControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(data), true)

            expect(maintModalService().applyChanges).toHaveBeenCalledWith(jasmine.objectContaining(data), jasmine.objectContaining(options), true, false, undefined);
        });

        describe('on navigate', function() {
            it('navigates if the form is pristine', function() {
                var ctrl = controller({
                    mode: 'edit',
                    dataItem: 'dataItem'
                });
                ctrl.form = {
                    $pristine: true,
                    $validate: jasmine.createSpy().and.returnValue(false)
                };

                var result = ctrl.onNavigate();
                expect(result).toBe(true);
                expect(ctrl.form.$validate).not.toHaveBeenCalled();
            });

            it('applies changes automatically', function() {
                var ctrl = controller({
                    mode: 'edit',
                    dataItem: 'dataItem',
                    apply: jasmine.createSpy()
                });
                ctrl.form = {
                    $pristine: false,
                    $validate: jasmine.createSpy().and.returnValue(false)
                };

                var result = ctrl.onNavigate();
                expect(result).toBe(false);
                expect(ctrl.form.$validate).toHaveBeenCalled();
            });
        });
    });

    describe('isApplyEnabled', function() {
        it('calls isApplyEnabled from Service', function() {
            var ctrl = controller();
            ctrl.form = {};
            ctrl.isApplyEnabled();
            expect(workflowsEventControlService.isApplyEnabled).toHaveBeenCalledWith({});
        });
    });

    describe('dismiss', function() {
        it('calls uibModalInstance dismiss', function() {
            var ctrl = controller();
            ctrl.dismiss();
            expect(modalInstance.dismiss).toHaveBeenCalled();
        });
    });

    describe('hasUnsavedChanges', function() {
        it('returns true when form is dirty', function() {
            var ctrl = controller();
            ctrl.form = {
                $dirty: true
            };
            expect(ctrl.hasUnsavedChanges()).toBe(true);

            ctrl.form.$dirty = false;
            expect(ctrl.hasUnsavedChanges()).toBe(false);
        });
    });
});