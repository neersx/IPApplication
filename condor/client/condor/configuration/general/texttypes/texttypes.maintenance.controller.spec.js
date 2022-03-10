describe('inprotech.configuration.general.textTypes.textTypeMaintenanceController', function() {
    'use strict';

    var controller, scope, textTypesSvc, notificationSvc, uibModalInstance, entityStates;
    beforeEach(function() {
        module('inprotech.configuration.general.texttypes');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.texttypes', 'inprotech.mocks', 'inprotech.mocks.components.notification']);

            notificationSvc = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationSvc);

            textTypesSvc = $injector.get('TextTypeServiceMock');
            $provide.value('textTypesService', textTypesSvc);

            uibModalInstance = $injector.get('ModalInstanceMock');
            $provide.value('$uibModalInstance', uibModalInstance);
        });
    });

    beforeEach(inject(function($rootScope, $controller, states) {
        controller = function(options) {
            if (options == null) {
                options = {
                    id: 'TextTypeMaintenance',
                    entity: {
                        state: states.normal
                    }
                };
            }
            scope = $rootScope.$new();
            entityStates = states;
            var ctrl = $controller('TextTypeMaintenanceController', {
                $scope: scope,
                options: _.extend({}, options)
            });

            return ctrl;
        };
    }));
    describe('cancel', function() {
        it('should close modal instance', function() {
            var ctrl = controller();
            ctrl.cancel();

            expect(uibModalInstance.close).toHaveBeenCalled();
        });
    });
    describe('isEditState', function() {
        it('should return true when state is updating', function() {
            var ctrl = controller({
                entity: {
                    state: "updating"
                }
            });
            expect(ctrl.isEditState()).toEqual(true);
        });
        it('should return false when state is not updating', function() {
            var ctrl = controller({
                entity: {
                    state: entityStates.adding
                }
            });
            expect(ctrl.isEditState()).toEqual(false);
        });
    });
    describe('validateCheckboxes', function() {
        it('should return true if Cases radio button is selected', function() {
            var ctrl = controller({
                entity: {
                    usedByName: false
                }
            });

            expect(ctrl.validateCheckboxes()).toEqual(true);
        });
        it('should return false if Names radio button is selected but none of Staff, Individual and Organisation is checked', function() {
            var ctrl = controller({
                entity: {
                    usedByName: true,
                    usedByEmployee: false,
                    usedByIndividual: false,
                    usedByOrganisation: false
                }
            });

            expect(ctrl.validateCheckboxes()).toEqual(false);
        });
        it('should return true if Names radio button is selected and any of Staff, Individual and Organisation is checked', function() {
            var ctrl = controller({
                entity: {
                    usedByName: true,
                    usedByEmployee: false,
                    usedByIndividual: true,
                    usedByOrganisation: false
                }
            });

            expect(ctrl.validateCheckboxes()).toEqual(true);
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
            ctrl.form.maintenance = { $setPristine: jasmine.createSpy() };
            ctrl.save();
            expect(ctrl.form.maintenance.$setPristine).toHaveBeenCalled();
            expect(notificationSvc.success).toHaveBeenCalled();
        });
    });
    describe('afterSave', function() {
        it('should close modal instance', function() {
            var ctrl = controller({
                entity: {
                    id: 'C',
                    state: entityStates.adding
                }
            });
            textTypesSvc.savedTextTypeIds = ['A'];
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result = {
                result: 'success',
                updatedId: 'C'
            };

            ctrl.afterSave(response);

            expect(textTypesSvc.savedTextTypeIds).toEqual(['A', 'C']);
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
                    field: 'textTypeCode',
                    topic: 'error',
                    message: 'field.errors.notunique'
                }
            };
            ctrl.afterSave(response);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                title: 'modal.unableToComplete',
                message: ctrl.getError('textTypeCode').topic,
                errors: _.where(response.data.result.errors, {
                    field: null
                })
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