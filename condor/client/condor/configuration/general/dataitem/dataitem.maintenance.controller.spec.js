describe('inprotech.configuration.general.dataitem.DataItemMaintenanceConfigController', function() {
    'use strict';

    var controller, dataItemService, notificationSvc, uibModalInstance, entityStates, options;

    beforeEach(function() {
        module('inprotech.configuration.general.dataitem');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.dataitem', 'inprotech.mocks', 'inprotech.mocks.components.notification']);

            notificationSvc = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationSvc);

            dataItemService = $injector.get('DataItemServiceMock');
            $provide.value('dataItemService', dataItemService);

            uibModalInstance = $injector.get('ModalInstanceMock');
            $provide.value('$uibModalInstance', uibModalInstance);
        });
    });

    beforeEach(inject(function($controller, states) {
        entityStates = states;
        options = {
            id: 'DataItemMaintenance',
            entity: {
                state: states.normal
            },
            callbackFn: angular.noop
        };

        controller = function(options) {
            var ctrl = $controller('DataItemMaintenanceConfigController', {
                options: _.extend({}, options)
            });

            return ctrl;
        };
    }));
    describe('cancel', function() {
        it('should close modal instance', function() {
            var ctrl = controller(options);
            ctrl.cancel();

            expect(uibModalInstance.close).toHaveBeenCalled();
        });
    });
    describe('dismissAll', function() {
        it('should cancel', function() {
            options.entity.state = entityStates.normal;
            var ctrl = controller(options);
            ctrl.form = {
                maintenance: {
                    $dirty: false
                }
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
        it('should add entity', function() {
            options.entity.state = entityStates.adding;

            var ctrl = controller(options);

            ctrl.form.maintenance = {
                $invalid: false
            };

            ctrl.save();

            expect(uibModalInstance.close).toHaveBeenCalled();
            expect(notificationSvc.success).toHaveBeenCalled();
        });
        it('should add entity when duplicate option is selected', function() {
            options.entity.state = entityStates.duplicating;

            var ctrl = controller(options);

            ctrl.form.maintenance = {
                $invalid: false
            };

            ctrl.save();

            expect(uibModalInstance.close).toHaveBeenCalled();
            expect(notificationSvc.success).toHaveBeenCalled();
        });
        it('should update entity', function() {
            options.entity = {
                state: entityStates.updating,
                isSqlStatement: true,
                sql: {
                    sqlStatement: "SELECT * FROM ITEM"
                }
            };

            var ctrl = controller(options);

            ctrl.form.maintenance = {
                $setPristine: jasmine.createSpy(),
                $invalid: false,
                code: {
                    $dirty: true
                }
            };

            ctrl.save();
            expect(notificationSvc.success).toHaveBeenCalled();
        });
    });
    describe('afterSave', function() {
        it('should close modal instance', function() {
            options.entity.id = 3;
            options.entity.state = entityStates.adding;

            var ctrl = controller(options);

            dataItemService.savedDataItemIds = [1];
            var response = {
                data: {}
            };
            response.data = {
                result: 'success',
                updatedId: 3
            };

            ctrl.afterSave(response);

            expect(dataItemService.savedDataItemIds).toEqual([1, 3]);
            expect(uibModalInstance.close).toHaveBeenCalled();
            expect(notificationSvc.success).toHaveBeenCalled();
        });
        it('should call alert when there is error', function() {
            options.entity.state = entityStates.normal;
            var ctrl = controller(options);
            var response = {
                data: {
                    errors: [{
                        id: null,
                        field: 'name',
                        topic: 'error',
                        message: 'error'
                    }]
                }
            };

            ctrl.afterSave(response);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                title: 'modal.unableToComplete',
                message: ctrl.getError('name').topic,
                errors: _.where(response.data.errors, {
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
                        errors: []
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