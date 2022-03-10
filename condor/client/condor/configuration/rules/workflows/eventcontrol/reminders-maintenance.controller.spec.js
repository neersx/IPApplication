describe('RemindersMaintenanceController', function() {
    'use strict';

    var scope, controller, modalInstance, notificationService, workflowsEventControlService, maintModalService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module('inprotech.core');

        module(function() {
            modalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock');
            notificationService = test.mock('notificationService');
            workflowsEventControlService = test.mock('workflowsEventControlService');
            maintModalService = test.mock('maintenanceModalService');
        });

        inject(function($rootScope, $controller) {
            scope = $rootScope.$new();
            scope.$emit = jasmine.createSpy();
            controller = function(options) {
                var ctrl = $controller('RemindersMaintenanceController', {
                    $scope: scope,
                    options: _.extend({}, options)
                });

                return ctrl;
            };
        });
    });

    describe('initialise', function() {
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
                    sendToStaff: true,
                    sendToSignatory: true,
                    repeatEvery: null,
                    abc: 'abc'
                },
                apply: jasmine.any(Function),
                isApplyEnabled: jasmine.any(Function),
                dismiss: jasmine.any(Function),
                hasUnsavedChanges: jasmine.any(Function),
                onRecurringChange: jasmine.any(Function),
                clearRelationship: jasmine.any(Function),
                isRelationshipDisabled: jasmine.any(Function),
                isUseAlternateMessageDisabled: jasmine.any(Function)
            }));
        });

        it('initialises title for add mode', function() {
            var ctrl = controller({
                mode: 'add'
            });
            expect(ctrl.title).toBe('.addTitle');
        });

        it('initialises title for edit mode', function() {
            var ctrl = controller({
                mode: 'edit'
            });
            expect(ctrl.title).toBe('.editTitle');
        });

        describe('should get correct recurring', function() {
            it('should enable recurring when repeatEvery has value', function() {
                var ctrl = controller({
                    dataItem: {
                        repeatEvery: 'abc'
                    }
                });

                expect(ctrl.recurring).toEqual(true);
            });

            it('should enable recurring when stopTime has value', function() {
                var ctrl = controller({
                    dataItem: {
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
                sendToStaff: true,
                sendToSignatory: true,
                repeatEvery: null
            });
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

        describe('atLeastOnRecipient', function() {
            it('should show warning if none of staff, signatoy, criticalList, name and nameTypes have value', function() {
                var ctrl = controller({
                    dataItem: {
                        sendToStaff: false,
                        sendToSignatory: false,
                        sendToCriticalList: false,
                        name: null,
                        nameTypes: null
                    }
                });

                ctrl.form = {
                    $validate: _.constant(true),
                    $dirty: true
                };

                ctrl.apply();

                expect(notificationService.alert).toHaveBeenCalled();
            });

            it('should not show warning if staff is checked', function() {
                var ctrl = controller({
                    dataItem: {
                        sendToStaff: true,
                        sendToSignatory: false,
                        sendToCriticalList: false,
                        name: null,
                        nameTypes: null
                    }
                });

                ctrl.form = {
                    $validate: _.constant(true),
                    $dirty: true
                };

                ctrl.apply();

                expect(notificationService.alert).not.toHaveBeenCalled();
            });

            it('should not show warning if signatory is checked', function() {
                var ctrl = controller({
                    dataItem: {
                        sendToStaff: false,
                        sendToSignatory: true,
                        sendToCriticalList: false,
                        name: null,
                        nameTypes: null
                    }
                });

                ctrl.form = {
                    $validate: _.constant(true),
                    $dirty: true
                };

                ctrl.apply();

                expect(notificationService.alert).not.toHaveBeenCalled();
            });

            it('should not show warning if criticalList is checked', function() {
                var ctrl = controller({
                    dataItem: {
                        sendToStaff: false,
                        sendToSignatory: false,
                        sendToCriticalList: true,
                        name: null,
                        nameTypes: null
                    }
                });

                ctrl.form = {
                    $validate: _.constant(true),
                    $dirty: true
                };

                ctrl.apply();

                expect(notificationService.alert).not.toHaveBeenCalled();
            });

            it('should not show warning if name has value', function() {
                var ctrl = controller({
                    dataItem: {
                        sendToStaff: false,
                        sendToSignatory: false,
                        sendToCriticalList: false,
                        name: 'name',
                        nameTypes: null
                    }
                });

                ctrl.form = {
                    $validate: _.constant(true),
                    $dirty: true
                };

                ctrl.apply();

                expect(notificationService.alert).not.toHaveBeenCalled();
            });

            it('should not show warning if nametype has value', function() {
                var ctrl = controller({
                    dataItem: {
                        sendToStaff: false,
                        sendToSignatory: false,
                        sendToCriticalList: true,
                        name: null,
                        nameTypes: 'nameTypes'
                    }
                });

                ctrl.form = {
                    $validate: _.constant(true),
                    $dirty: true
                };

                ctrl.apply();

                expect(notificationService.alert).not.toHaveBeenCalled();
            });
        });

        it('sets flags and calls apply method for add', function () {
            var data = { name: 'added' };
            var options = {
                mode: 'add',
                isAddAnother: true
            };

            var ctrl = controller(options);
            ctrl.formData = data;
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };

            ctrl.apply();

            expect(workflowsEventControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(data), false)

            expect(maintModalService().applyChanges).toHaveBeenCalledWith(jasmine.objectContaining(data), jasmine.objectContaining(options), false, true, undefined);
        });

        it('sets flags and calls apply method for edit', function () {
            var data = { name: 'edited' };
            var options = {
                mode: 'edit',
                isAddAnother: false
            };

            var ctrl = controller(options);
            ctrl.formData = data;
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
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
        });
    });

    describe('clearRelationship', function() {
        it('relationship should be cleared', function() {
            var ctrl = controller({
                dataItem: {
                    nameTypes: null,
                    name: null,
                    relationship: 'some'
                }
            });
            ctrl.clearRelationship();
            expect(ctrl.formData.relationship).toEqual(null);
        });

        it('relationship should not be cleared when nameTypes has value', function() {
            var ctrl = controller({
                dataItem: {
                    nameTypes: {},
                    name: null,
                    relationship: 'some'
                }
            });
            ctrl.clearRelationship();
            expect(ctrl.formData.relationship).toEqual('some');
        });

        it('relationship should not be cleared when name has value', function() {
            var ctrl = controller({
                dataItem: {
                    nameTypes: null,
                    name: {},
                    relationship: 'some'
                }
            });
            ctrl.clearRelationship();
            expect(ctrl.formData.relationship).toEqual('some');
        });
    });

    describe('isRelationshipDisabled', function() {
        it('should be disabled when both nameTypes and name has no value', function() {
            var ctrl = controller({
                dataItem: {
                    nameTypes: [],
                    name: null
                }
            });
            var result = ctrl.isRelationshipDisabled();
            expect(result).toEqual(true);
        });

        it('should not be disabled when nameTypes has value', function() {
            var ctrl = controller({
                dataItem: {
                    nameTypes: ['abc'],
                    name: null
                }
            });
            var result = ctrl.isRelationshipDisabled();
            expect(result).toEqual(false);
        });

        it('should not be disabled when name has value', function() {
            var ctrl = controller({
                dataItem: {
                    nameTypes: [],
                    name: {}
                }
            });
            var result = ctrl.isRelationshipDisabled();
            expect(result).toEqual(false);
        });
    });

    describe('isUseAlternateMessageDisabled', function() {
        it('should disable if Alternate Message is empty or null', function() {
            var c = controller();
            c.formData = { alternateMessage: null };
            expect(c.isUseAlternateMessageDisabled()).toBe(true);


            c.formData.alternateMessage = "";
            expect(c.isUseAlternateMessageDisabled()).toBe(true);

            c.formData.alternateMessage = "AAA";
            expect(c.isUseAlternateMessageDisabled()).toBe(false);
        });

        it('should default the checkbox to off if Alternate Message is empty or null', function() {
            var c = controller();
            c.formData = { alternateMessage: null, useOnAndAfterDueDate: true };
            
            var result = c.isUseAlternateMessageDisabled();
            expect(result).toBe(true);
            expect(c.formData.useOnAndAfterDueDate).toBe(false);
        });

        it('call warning On NegativeNumber method when no. is not negative ', function(){
            var ctrl =controller();
            ctrl.formData = {
                startBefore: {
                  value: 7
                }
              };
            expect(ctrl.warningOnNegativeNumber('value')).toEqual(null);
        });
        it('call warning On NegativeNumber method when no. is negative', function(){
            var ctrl =controller();
            ctrl.formData = {
                startBefore: {
                  value: -7
                }
              };
            expect(ctrl.warningOnNegativeNumber('value')).not.toEqual(null);
        });

    });
});
