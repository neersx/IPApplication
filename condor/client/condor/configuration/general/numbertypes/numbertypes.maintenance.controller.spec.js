describe('inprotech.configuration.general.numberTypes.NumberTypeMaintenanceController', function() {
    'use strict';

    var controller, numberTypesSvc, notificationSvc, uibModalInstance, entityStates, options;

    beforeEach(function() {
        module('inprotech.configuration.general.numbertypes');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.numbertypes', 'inprotech.mocks', 'inprotech.mocks.components.notification']);

            notificationSvc = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationSvc);

            numberTypesSvc = $injector.get('NumberTypeServiceMock');
            $provide.value('numberTypesService', numberTypesSvc);

            uibModalInstance = $injector.get('ModalInstanceMock');
            $provide.value('$uibModalInstance', uibModalInstance);
        });
    });

    beforeEach(inject(function($controller, states) {
        entityStates = states;
        options = {
            id: 'NumberTypeMaintenance',
            entity: {
                state: states.normal,
                numberTypeCode: 'E'
            }
        };

        controller = function(options) {
            var ctrl = $controller('NumberTypeMaintenanceController', {
                options: _.extend({}, options)
            });

            return ctrl;
        };
    }));
    describe('clearNumberTypeCode', function() {
        it('should blank Number Type Code in case of duplicate', function() {
            options.entity.state = entityStates.duplicating;
            var ctrl = controller(options);
            ctrl.clearNumberTypeCode();
            expect(options.entity.numberTypeCode).toEqual(null);
        });
    });
    describe('cancel', function() {
        it('should close modal instance', function() {
            options.entity.state = entityStates.normal;
            var ctrl = controller(options);
            ctrl.cancel();

            expect(uibModalInstance.close).toHaveBeenCalled();
        });
    });
    describe('isEditState', function() {
        it('should return true when state is updating', function() {
            options.entity.state = entityStates.updating;
            var ctrl = controller(options);

            expect(ctrl.isEditState()).toEqual(true);
        });
        it('should return false when state is not updating', function() {
            options.entity.state = entityStates.adding;
            var ctrl = controller(options);

            expect(ctrl.isEditState()).toEqual(false);
        });
    });
    describe('dismissAll', function() {
        it('should cancel', function() {
            options.entity.state = entityStates.normal;
            var ctrl = controller(options);
            ctrl.form.maintenance = {
                $dirty: false
            };
            spyOn(ctrl, 'cancel');
            ctrl.dismissAll();

            expect(ctrl.cancel).toHaveBeenCalled();
        });
        it('should prompt notification if there are any unsaved changes', function() {
            options.entity.state = entityStates.normal;
            var ctrl = controller(options);
            ctrl.form.maintenance = {
                $dirty: true
            };

            ctrl.dismissAll();

            expect(notificationSvc.discard).toHaveBeenCalled();
        });
        it('should close modal dialog when discard button is clicked', function() {
            options.entity.state = entityStates.normal;
            var ctrl = controller(options);
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
            var ctrl = controller({
                entity: {
                    state: entityStates.adding
                }
            });
            ctrl.form.maintenance = {
                $invalid: false
            };
            ctrl._isSaving = true;

            ctrl.save();
            expect(uibModalInstance.close).not.toHaveBeenCalled();
        });
        it('should add entity', function() {
            var ctrl = controller({
                entity: {
                    state: entityStates.adding
                }
            });
            ctrl.form.maintenance = {
                $invalid: false
            };

            ctrl.save();
            expect(uibModalInstance.close).toHaveBeenCalled();
            expect(notificationSvc.success).toHaveBeenCalled();
        });
        it('should update entity', function() {
            var ctrl = controller({
                entity: {
                    state: entityStates.updating
                }
            });
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
            var ctrl = controller({
                entity: {
                    id: 3,
                    state: entityStates.adding
                }
            });
            numberTypesSvc.savedNumberTypeIds = [1];
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

            expect(numberTypesSvc.savedNumberTypeIds).toEqual([1, 3]);
            expect(uibModalInstance.close).toHaveBeenCalled();
            expect(notificationSvc.success).toHaveBeenCalled();
        });
        it('should call alert when there is error', function() {
            options.entity.state = entityStates.normal;
            var ctrl = controller(options);
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result.errors = {
                errors: {
                    id: null,
                    field: 'numberTypeCode',
                    topic: 'error',
                    message: 'field.errors.notunique'
                }
            };
            ctrl.afterSave(response);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                title: 'modal.unableToComplete',
                message: ctrl.getError('numberTypeCode').topic,
                errors: _.where(response.data.result.errors, {
                    field: null
                })
            });
        });
    });
    describe('afterSaveError', function() {
        it('should call alert', function() {
            options.entity.state = entityStates.normal;
            var ctrl = controller(options);
            var response = {
                data: {
                    result: {
                        result: {
                            errors: []
                        }
                    }
                }
            };
            ctrl.afterSaveError(response);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                message: 'modal.alert.unsavedchanges',
                errors: _.where(response.data.result.errors, {
                    field: null
                })
            });
        });
    });
});