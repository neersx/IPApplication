describe('inprotech.configuration.general.nameTypes.NameTypeMaintenanceController', function() {
    'use strict';

    var controller, nameTypesSvc, entityStates, notificationSvc, uibModalInstance, options, modalSvc;

    beforeEach(function() {
        module('inprotech.configuration.general.nametypes');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.nametypes', 'inprotech.mocks', 'inprotech.mocks.components.notification']);
            $provide.value('nameTypesService', $injector.get('NameTypeServiceMock'));
            $provide.value('$uibModalInstance', $injector.get('ModalInstanceMock'));
            $provide.value('notificationService', $injector.get('notificationServiceMock'));
            $provide.value('modalService', $injector.get('modalServiceMock'));
        });
    });

    beforeEach(inject(function($controller, nameTypesService, $uibModalInstance, notificationService, states, modalService) {
        nameTypesSvc = nameTypesService;
        entityStates = states;
        notificationSvc = notificationService;
        uibModalInstance = $uibModalInstance;
        modalSvc = modalService;

        options = {
            id: 'NameTypeMaintenance',
            entity: {
                nameTypeCode: 'E'
            }
        };

        controller = function(dependencies) {
            if (!dependencies) {
                dependencies = {
                    $uibModalInstance: uibModalInstance,
                    nameTypesService: nameTypesSvc,
                    states: entityStates,
                    notificationService: notificationSvc,
                    modalService: modalSvc,
                    options: _.extend({}, options)
                };
            }

            return $controller('NameTypeMaintenanceController', dependencies);
        };
    }));
    describe('clearNameTypeCode', function() {
        it('should blank Name Type Code in case of duplicate', function() {
            var c = controller();
            c.entity.state = entityStates.duplicating;
            c.clearNameTypeCode();
            expect(c.entity.nameTypeCode).toEqual(null);
        });
    });
    describe('cancel', function() {
        it('should restore entity and close modal instance', function() {
            var c = controller();

            c.cancel();

            expect(uibModalInstance.dismiss).toHaveBeenCalledWith('Cancel');
        });
    });
    describe('dismissAll', function() {
        it('should cancel', function() {
            var c = controller();
            c.maintenance = {
                $dirty: false
            };
            spyOn(c, 'cancel');

            c.dismissAll();

            expect(c.cancel).toHaveBeenCalled();
        });
        it('should prompt notification if there are any unsaved changes', function() {
            var c = controller();
            c.maintenance = {
                $dirty: true
            };

            c.dismissAll();

            expect(notificationSvc.discard).toHaveBeenCalled();
        });
        it('should close modal dialog when discard button is clicked', function() {
            var c = controller();
            c.maintenance = {
                $dirty: true
            };
            notificationSvc.discard.confirmed = true;
            spyOn(c, 'cancel');

            c.dismissAll();

            expect(c.cancel).toHaveBeenCalled();
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
            var c = controller();
            c.maintenance = {
                $invalid: false
            };
            c.entity.state = entityStates.adding;

            c.save();

            expect(uibModalInstance.close).toHaveBeenCalled();
        });
        it('should update entity', function() {
            var c = controller();
            c.maintenance = {
                $invalid: false
            };
            c.entity.state = entityStates.updating;

            c.save();

            expect(uibModalInstance.close).toHaveBeenCalled();
        });
    });
    describe('afterSave', function() {
        it('should close modal instance', function() {
            var c = controller();
            nameTypesSvc.savedNameTypeIds = [1];
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result = {
                result: 'success',
                updatedId: 3
            };

            c.afterSave(response);

            expect(nameTypesSvc.savedNameTypeIds).toEqual([1, 3]);
            expect(uibModalInstance.close).toHaveBeenCalled();
        });
        it('should open priority window modal instance after add', inject(function($timeout) {
            var c = controller();
            c.entity.state = 'adding';
            nameTypesSvc.savedNameTypeIds = [1];
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result = {
                result: 'success',
                updatedId: 3
            };

            c.afterSave(response);

            $timeout.flush();
            expect(modalSvc.openModal).toHaveBeenCalledWith(jasmine.objectContaining(_.extend({
                launchSrc: 'maintenance',
                id: 'NameTypesOrder',
                controllerAs: 'vm'
            })));

        }));
        it('should open priority window modal instance after duplicate', inject(function($timeout) {
            var c = controller();
            c.entity.state = 'duplicating';
            nameTypesSvc.savedNameTypeIds = [1];
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result = {
                result: 'success',
                updatedId: 3
            };

            c.afterSave(response);

            $timeout.flush();
            expect(modalSvc.openModal).toHaveBeenCalledWith(jasmine.objectContaining(_.extend({
                launchSrc: 'maintenance',
                id: 'NameTypesOrder',
                controllerAs: 'vm'
            })));

        }));
        it('should call alert when there is error', function() {
            var c = controller();
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result.errors = {
                errors: {
                    id: null,
                    field: 'nameTypeCode',
                    topic: 'error',
                    message: 'field.errors.notunique'
                }
            };

            c.afterSave(response);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                title: 'modal.unableToComplete',
                message: c.getError('nameTypeCode').topic,
                errors: _.where(response.data.result.errors, {
                    field: null
                })
            });
        });
    });
    describe('afterSaveError', function() {
        it('should call alert', function() {
            var c = controller();
            var response = {
                data: {
                    result: {
                        errors: []
                    }
                }
            };

            c.afterSaveError(response);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                message: 'modal.alert.unsavedchanges',
                errors: _.where(response.data.result.errors, {
                    field: null
                })
            });
        });
    });
    describe('isClassifiedChange', function() {
        it('should call notification confirm', function() {
            var c = controller();
            c.entity.state = entityStates.updating;
            c.entity.isClassified = true;
            c.isClassifiedChange();

            expect(notificationSvc.confirm).toHaveBeenCalledWith({
                title: 'modal.sameNameType.title',
                message: 'modal.sameNameType.message'
            });
        });
    });
    describe('toggleSelection', function() {
        it(' should set passed property to false', function() {
            var c = controller();
            c.entity.isStandardNameDisplayed = true;

            c.toggleSelection('isStandardNameDisplayed');

            expect(c.entity.isStandardNameDisplayed).toEqual(false);
        });
    });
    describe('onPathNameTypeChanged', function() {
        it(' should set pathNameRelation to null', function() {
            var c = controller();
            c.entity.pathNameTypePickList = null;

            c.onPathNameTypeChanged();

            expect(c.entity.updateFromParentNameType).toEqual(false);
            expect(c.entity.pathNameRelation).toEqual(null);
        });
    });
    describe('onPathRelationshipChanged', function() {
        it(' should set useHomeNameRelationship and useNameType to false', function() {
            var c = controller();
            c.entity.pathNameTypePickList = null;

            c.onPathRelationshipChanged();

            expect(c.entity.useHomeNameRelationship).toEqual(false);
            expect(c.entity.useNameType).toEqual(false);
        });
    });
    describe('text field change ', function() {
        it('Should mark data not supported false when on text field change with invalid values', function() {
            var c = controller();
            c.entity = {
                maximumAllowed: 9999
            };

            c.maintenance = {
                description: {
                    $setValidity: jasmine.createSpy()
                }
            };

            c.onChange();

            expect(c.maintenance.description.$setValidity).toHaveBeenCalledWith('notSupportedValue', false);
        });
        it('Should mark data not supported true when on text field change with valid values', function() {
            var c = controller();
            c.entity = {
                maximumAllowed: 10
            };

            c.maintenance = {
                description: {
                    $setValidity: jasmine.createSpy()
                }
            };

            c.onChange();

            expect(c.maintenance.description.$setValidity).toHaveBeenCalledWith('notSupportedValue', true);
        });
    });
});