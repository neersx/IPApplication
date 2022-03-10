describe('inprotech.configuration.general.status.StatusMaintenanceController', function() {
    'use strict';

    var controller, statusSvc, notificationSvc, uibModalInstance, options;

    beforeEach(function() {
        module('inprotech.configuration.general.status');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.components.notification', 'inprotech.mocks.configuration.general.status']);

            $provide.value('statusService', $injector.get('StatusServiceMock'));
            $provide.value('$uibModalInstance', $injector.get('ModalInstanceMock'));
            $provide.value('notificationService', $injector.get('notificationServiceMock'));
        });
    });

    beforeEach(inject(function($controller, statusService, $uibModalInstance, notificationService) {
        statusSvc = statusService;
        notificationSvc = notificationService;
        uibModalInstance = $uibModalInstance;

        options = {
            id: 'StatusMaintenance',
            entity: {},
            supportData: {}
        };

        controller = function(dependencies) {
            if (!dependencies) {
                dependencies = {
                    $uibModalInstance: uibModalInstance,
                    statusService: statusSvc,
                    notificationService: notificationSvc,
                    options: _.extend({}, options)
                };
            }

            return $controller('StatusMaintenanceController', dependencies);
        };
    }));


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
        it('should call alert when there is error', function () {
            var c = controller();
             c.maintenance = {
                $invalid: false
            };
            c.entity.state = 'adding';
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.errors = {
                errors: {
                    id: null,
                    field: 'internalName',
                    topic: 'error',
                    message: 'field.errors.notunique'
                }
            };
            c.afterSave(response);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                title: 'modal.unableToComplete',
                message: c.getError('internalName').topic,
                errors: _.where(response.data.result.errors, {
                    field: null
                })
            });
        });
        it('should add entity', function() {
            var c = controller();
            c.maintenance = {
                $invalid: false
            };
            c.entity.state = 'adding';

            c.save();

            expect(uibModalInstance.close).toHaveBeenCalled();
        });
        it('should update entity', function() {
            var c = controller();
            c.maintenance = {
                $invalid: false
            };
            c.entity.state = 'updating';

            c.save();

            expect(uibModalInstance.close).toHaveBeenCalled();
        });
    });
});