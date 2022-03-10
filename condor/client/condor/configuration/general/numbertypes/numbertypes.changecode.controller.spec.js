describe('inprotech.configuration.general.numberTypes.ChangeNumberTypeCodeController', function() {
    'use strict';

    var controller, scope, numberTypesSvc, notificationSvc, uibModalInstance;
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

    beforeEach(inject(function($rootScope, $controller) {
        controller = function(options) {
            scope = $rootScope.$new();
            var ctrl = $controller('ChangeNumberTypeCodeController', {
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
        it('should change number type code', function() {
            var ctrl = controller({
                entity: {
                    id: 1,
                    numberTypeCode: 'C',
                    newNumberTypeCode: 'Z'
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
                    id: 2
                }});
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
            var ctrl = controller();
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
