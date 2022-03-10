describe('inprotech.configuration.general.textTypes.ChangeTextTypeCodeController', function() {
    'use strict';

    var controller, scope, textTypesSvc, notificationSvc, uibModalInstance;
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

    beforeEach(inject(function($rootScope, $controller) {
        controller = function(options) {
            scope = $rootScope.$new();
            var ctrl = $controller('ChangeTextTypeCodeController', {
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
    describe('dismissAll', function() {
        it('should cancel', function() {
            var ctrl = controller();
            var client = {
                $dirty: false
            };
            spyOn(ctrl, 'cancel');
            ctrl.dismissAll(client);

            expect(ctrl.cancel).toHaveBeenCalled();
        });
        it('should prompt notification if there are any unsaved changes', function() {
            var ctrl = controller();
            var client = {
                $dirty: true
            };

            ctrl.dismissAll(client);

            expect(notificationSvc.discard).toHaveBeenCalled();
        });
        it('should close modal dialog when discard button is clicked', function() {
            var ctrl = controller();
            var client = {
                $dirty: true
            };
            notificationSvc.discard.confirmed = true;
            spyOn(ctrl, 'cancel');
            ctrl.dismissAll(client);

            expect(ctrl.cancel).toHaveBeenCalled();
        });
    });
    describe('save', function() {
        it('should call notificationService if entity is invalid', function() {
            var ctrl = controller();
            var client = {
                $invalid: true
            };
            ctrl.save(client);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                title: 'modal.unableToComplete',
                message: 'modal.alert.unsavedchanges'
            });
        });
        it('should change text type code', function() {
            var ctrl = controller({
                entity: {
                    id: 'C',
                    newTextTypeCode: 'Z'
                }
            });
            var client = {
                $invalid: false
            };

            ctrl.save(client);            
            expect(uibModalInstance.close).toHaveBeenCalled();
            expect(notificationSvc.success).toHaveBeenCalled();
        });        
    });
    describe('afterSave', function() {
        it('should close modal instance', function() {
            var ctrl = controller({
                entity: {
                    id: 'B'
                }});
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
                title: 'modal.unableToComplete',
                message: 'modal.alert.unsavedchanges',
                errors: _.where(response.data.errors, {
                    field: null
                })
            });
        });
    });
});
