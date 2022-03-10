describe('inprotech.configuration.general.namerestrictions.NameRestrictionsController', function() {
    'use strict';

    var controller, nameRestrictionsSvc, notificationSvc, uibModalInstance, options, nameRestActions;
    beforeEach(function() {
        module('inprotech.configuration.general.namerestrictions');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.namerestrictions', 'inprotech.mocks', 'inprotech.mocks.components.notification']);

            notificationSvc = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationSvc);

            nameRestrictionsSvc = $injector.get('NameRestrictionsServiceMock');
            $provide.value('nameRestrictionsService', nameRestrictionsSvc);

            uibModalInstance = $injector.get('ModalInstanceMock');
            $provide.value('$uibModalInstance', uibModalInstance);
        });
    });


    beforeEach(inject(function($controller, nameRestrictionsService, $uibModalInstance, notificationService, nameRestrictionActions) {
        nameRestrictionsSvc = nameRestrictionsService;
        notificationSvc = notificationService;
        uibModalInstance = $uibModalInstance;
        nameRestActions = nameRestrictionActions;

        options = {
            id: 'NameRestrictionsMaintenance',
            entity: {
                action: 1
            },
            viewData: [{
                    type: 1
                },
                {
                    type: 2
                }
            ]
        };

        controller = function(dependencies) {
            if (!dependencies) {
                dependencies = {
                    $uibModalInstance: uibModalInstance,
                    nameRestrictionsService: nameRestrictionsSvc,
                    notificationService: notificationSvc,
                    nameRestrictionActions: nameRestActions,
                    options: _.extend({}, options)
                };
            }
            return $controller('NameRestrictionsMaintenanceController', dependencies);
        };
    }));

    describe('cancel', function() {
        it('should close modal instance', function() {
            var ctrl = controller();
            ctrl.cancel();

            expect(uibModalInstance.close).toHaveBeenCalled();
        });
    });

    describe('isPasswordDisabled', function() {
        it('should return true when selected action is null', function() {
            var ctrl = controller();
            expect(ctrl.isPasswordDisabled()).toEqual(true);

        });
        it('should return false when selected action requires password', function() {
            var ctrl = controller();
            ctrl.selectedAction.type = nameRestActions.DisplayWarningWithPassword;
            expect(ctrl.isPasswordDisabled()).toEqual(false);

        });
    });

    describe('onActionChanged', function() {
        it('should set password to null if action type is not equal to 2', function() {
            var ctrl = controller();
            ctrl.form.maintenance = {
                password: '1234'
            };
            ctrl.form.maintenance.password = {
                $resetErrors: jasmine.createSpy()
            };
            ctrl.selectedAction.type = 1;
            ctrl.onActionChanged();
            expect(ctrl.form.maintenance.password.$resetErrors).toHaveBeenCalled();
            expect(ctrl.entity.password).toBeNull();
        });
        it('should set password not to null if action type is equal to 2', function() {
            var ctrl = controller();
            ctrl.form.maintenance = {
                password: '1234'
            };
            ctrl.selectedAction.type = nameRestActions.DisplayWarningWithPassword;
            ctrl.onActionChanged();
            expect(ctrl.entity.password).not.toBeNull();
        });
    });

    describe('isEditState', function() {
        it('should return false when state is adding', function() {
            var ctrl = controller();
            ctrl.entity.state = 'adding';
            expect(ctrl.isEditState()).toEqual(false);
        });
        it('should retur true when state is updating', function() {
            var ctrl = controller();
            ctrl.entity.state = 'updating';
            expect(ctrl.isEditState()).toBe(true);
        });
    });

    describe('dismissAll', function() {
        it('should cancel', function() {
            var ctrl = controller();
            ctrl.form.maintenance = {
                $dirty: false
            };
            spyOn(ctrl, 'cancel');
            ctrl.dismissAll();

            expect(ctrl.cancel).toHaveBeenCalled();
        });
        it('should prompt notification if there are any unsaved changes', function() {
            var ctrl = controller();
            ctrl.form.maintenance = {
                $dirty: true
            };

            ctrl.dismissAll();

            expect(notificationSvc.discard).toHaveBeenCalled();
        });
        it('should close modal dialog when discard button is clicked', function() {
            var ctrl = controller();
            ctrl.form.maintenance = {
                $dirty: true
            };

            notificationSvc.discard.confirmed = true;
            spyOn(ctrl, 'cancel');
            ctrl.dismissAll();

            expect(ctrl.cancel).toHaveBeenCalled();
        });
    });
    describe('save', function() {
        it('should not save if already saving', function() {
            var c = controller();
            c.maintenance = {
                $invalid: false
            };
            c._isSaving = true;

            c.save();
            expect(uibModalInstance.close).not.toHaveBeenCalled();
        });
        it('should add entity', function() {
            var ctrl = controller();
            ctrl.form.maintenance = {
                $invalid: false
            };

            ctrl.save();
            expect(uibModalInstance.close).toHaveBeenCalled();
            expect(notificationSvc.success).toHaveBeenCalled();
        });
        it('should update entity', function() {
            var ctrl = controller();
            ctrl.entity.state = 'updating';

            ctrl.form.maintenance = {
                $invalid: false
            };
            ctrl.form.maintenance = {
                $setPristine: jasmine.createSpy()
            };
            ctrl.save();
            expect(ctrl.form.maintenance.$setPristine).toHaveBeenCalled();
            expect(notificationSvc.success).toHaveBeenCalled();
        });
    });
    describe('afterSave', function() {
        it('should close modal instance', function() {
            var ctrl = controller();

            nameRestrictionsSvc.savedNameRestrictionIds = [1];
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result = {
                result: 'success',
                updatedId: 3
            };

            ctrl.afterSave(response);

            expect(nameRestrictionsSvc.savedNameRestrictionIds).toEqual([1, 3]);
            expect(uibModalInstance.close).toHaveBeenCalled();
            expect(notificationSvc.success).toHaveBeenCalled();
        });
        it('should call alert when there is error', function() {
            var ctrl = controller();
            var response = {
                data: {
                    result: {}
                }
            };

            response.data.result.errors = {
                errors: {
                    id: null,
                    field: 'description',
                    topic: 'error',
                    message: 'field.errors.notunique'
                }
            };

            ctrl.afterSave(response);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                title: 'modal.unableToComplete',
                message: ctrl.getError('description').topic,
                errors: []
            });
        });
    });
    describe('afterSaveError', function() {
        it('should call alert', function() {
            var ctrl = controller();
            var response = {
                data: {
                    result: {
                        errors: {}
                    }
                }
            };
            ctrl.afterSaveError(response);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                message: 'modal.alert.unsavedchanges',
                errors: _.where(response.data.errors, {
                    field: null
                })
            });
        });
    });
});