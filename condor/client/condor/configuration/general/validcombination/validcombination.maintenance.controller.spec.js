describe('inprotech.configuration.general.validcombination.ValidCombinationMaintenanceController', function() {
    'use strict';

    var controller, scope, service, entityStates, notificationSvc, modalInstance, maintenanceService, validCombConfig, options;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.validcombination', 'inprotech.mocks', 'inprotech.mocks.components.notification']);
            $provide.value('validCombinationService', $injector.get('ValidCombinationServiceMock'));
            $provide.value('validCombinationMaintenanceService', $injector.get('ValidCombinationMaintenanceServiceMock'));
            $provide.value('$uibModalInstance', $injector.get('ModalInstanceMock'));
            $provide.value('notificationService', $injector.get('notificationServiceMock'));
        });
    });

    beforeEach(inject(function($rootScope, $controller, $uibModalInstance, notificationService, validCombinationService, states, validCombinationMaintenanceService, validCombinationConfig) {
        scope = $rootScope.$new();
        service = validCombinationService;
        maintenanceService = validCombinationMaintenanceService;
        entityStates = states;
        notificationSvc = notificationService;
        modalInstance = $uibModalInstance;
        validCombConfig = validCombinationConfig;
        options = {};
        options.entity = {};
        options.entity.state = entityStates.normal;
        options.selectedCharacteristic = {
            type: validCombConfig.searchType.default,
            description: ''
        };
        options.searchCriteria = {};

        controller = function(dependencies) {
            if (!dependencies) {
                dependencies = {
                    $uibModalInstance: modalInstance,
                    validcombinationService: service,
                    validcombinationMaintenanceService: maintenanceService,
                    states: entityStates,
                    notificationService: notificationSvc,
                    validCombinationConfig: validCombConfig,
                    modalOptions: options
                };
            }
            dependencies.$scope = scope;
            return $controller('ValidCombinationMaintenanceController', dependencies);
        };
    }));
    describe('isCopyChanged', function() {
        it('should restore entity and maintenance form', function() {
            var c = controller();
            c.entityState = 'adding';
            var client = {
                $dirty: true,
                $setPristine: jasmine.createSpy()
            };

            c.isCopyChanged(client);

            expect(c.copyEntity).toEqual({});
            expect(c.entity).toEqual({
                state: c.entityState
            });
            expect(client.$dirty).toEqual(false);
            expect(client.$setPristine).toHaveBeenCalled();
        });
    });
    describe('cancel', function() {
        it('should restore entity and close modal instance', function() {
            var c = controller();

            c.cancel();

            expect(modalInstance.dismiss).toHaveBeenCalledWith('Cancel');
        });
    });
    describe('dismissAll', function() {
        it('should cancel', function() {
            var c = controller();
            var client = {
                $dirty: false
            };

            c.entity = {
                picklistsDirty: function() {
                    return false;
                }
            };

            c.dismissAll(client);

            expect(modalInstance.dismiss).toHaveBeenCalledWith('Cancel');
        });
        it('should cancel copy', function() {
            var c = controller();
            c.isCopy = true;
            var client = {
                $dirty: false
            };
            c.copyEntity = {
                picklistsDirty: function() {
                    return false;
                }
            };
            c.dismissAll(client);

            expect(modalInstance.dismiss).toHaveBeenCalledWith('Cancel');
        });
        it('should prompt notification if there are any unsaved changes in copy', function() {
            var c = controller();
            c.isCopy = true;
            var client = {
                $dirty: false
            };
            c.copyEntity = {
                picklistsDirty: function() {
                    return true;
                }
            };
            c.dismissAll(client);

            expect(notificationSvc.discard).toHaveBeenCalled();
        });
        it('should prompt notification if there are any unsaved changes', function() {
            var c = controller();
            var client = {
                $dirty: true
            };
            c.selectedCharacteristic = {
                type: 'propertytype'
            };
            c.dismissAll(client);

            expect(notificationSvc.discard).toHaveBeenCalled();
        });
        it('should close modal dialog when discard button is clicked', function() {
            var c = controller();
            var client = {
                $dirty: true
            };
            notificationSvc.discard.confirmed = true;
            spyOn(c, 'cancel');
            c.dismissAll(client);

            expect(modalInstance.dismiss).toHaveBeenCalledWith('Cancel');
        });
    });
    describe('save', function() {
        it('should not save if already saving', function() {
            var c = controller();
            var client = {
                $invalid: false
            };
            c._isSaving = true;

            c.save(client);
            expect(modalInstance.close).not.toHaveBeenCalled();
        });
        it('should add entity', function() {
            var c = controller();
            var client = {
                $invalid: false
            };
            c.entity.state = entityStates.adding;

            c.save(client);

            expect(modalInstance.close).toHaveBeenCalled();
        });
        it('should update entity', function() {
            var c = controller();
            var client = {
                $invalid: false
            };
            c.entity.state = entityStates.updating;
            c.save(client);
            expect(modalInstance.close).toHaveBeenCalled();
        });
        it('should call copy and confirmation of selected characteristic', function() {
            var c = controller();
            c.isCopy = true;
            var client = {
                $dirty: false
            };
            c.copyEntity = {
                hasSameValue: function() {
                    return false;
                },
                fromJurisdiction: {
                    key: 'AU',
                    code: 'AU',
                    value: 'Australia'
                },
                status: true,
                checklist: true
            };
            spyOn(service, 'copy').and.callThrough();
            var selectedCharacterisics = [{
                description: 'validcombinations.status',
                isSelected: true
            }, {
                description: 'validcombinations.checklist',
                isSelected: true
            }];
            var expected = {
                confirmationMessage: 'validcombinations.confirmSaveCopyValidCombination',
                templateUrl: 'condor/configuration/general/validcombination/copyvalidcombination-confirmation.html',
                continue: 'modal.confirmation.save',
                cancel: 'modal.confirmation.cancel',
                selectedCharacterisics: selectedCharacterisics,
                fromJurisdiction: c.copyEntity.fromJurisdiction.value
            };

            c.save(client);

            expect(notificationSvc.confirm).toHaveBeenCalledWith(expected);
            expect(service.copy).toHaveBeenCalled();
        });
        it('should call alert if copy from and to is same', function() {
            var c = controller();
            c.isCopy = true;
            var client = {
                $dirty: false
            };

            c.copyEntity = {
                hasSameValue: function() {
                    return true;
                }
            };
            spyOn(c, 'enableCopySave').and.returnValue(true);
            c.save(client);

            expect(notificationSvc.alert).toHaveBeenCalled();
        });
    });
    describe('afterSave', function() {
        it('should close modal instance', function() {
            var c = controller();
            maintenanceService.savedKeys = [];
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result = {
                result: 'success',
                updatedKeys: {
                    countryId: '2',
                    propertyTypeId: '3'
                }
            };

            c.afterSave(response);

            expect(maintenanceService.addSavedKeys).toHaveBeenCalledWith(response.data.result.updatedKeys);
            expect(modalInstance.close).toHaveBeenCalled();
        });
        it('should launch set action order modal after succesful save', function() {
            var c = controller();
            c.isCopy = false;
            c.selectedCharacteristic = {
                type: 'action'
            };
            c.entity = {
                state: 'adding'
            };
            maintenanceService.savedKeys = [];
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result = {
                result: 'success',
                updatedKeys: {
                    countryId: '2',
                    propertyTypeId: '3'
                }
            };

            spyOn(c, 'launchActionOrder');

            c.afterSave(response);

            expect(maintenanceService.addSavedKeys).toHaveBeenCalledWith(response.data.result.updatedKeys);
            expect(modalInstance.close).toHaveBeenCalled();
            expect(c.launchActionOrder).toHaveBeenCalled();
        });
        it('should call confirmation dialog when there is confirmation', function() {
            var c = controller();
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result = {
                result: 'confirmation'
            };
            c.afterSave(response);

            expect(notificationSvc.confirm).toHaveBeenCalled();
        });
        it('should call add if user clicks Yes on confirmation dialog', function() {
            var c = controller();
            var response = {
                data: {
                    result: {}
                }
            };

            c.entity.jurisdictions = [{
                id: 'EP'
            }, {
                id: 'AU'
            }, {
                id: 'IN'
            }];
            response.data.result = {
                result: 'confirmation',
                validationMessage: 'duplicate entries',
                confirmationMessage: 'Confirm',
                countries: ['EP', 'AU'],
                countryKeys: ['EP', 'AU']
            };
            c.afterSave(response);

            expect(notificationSvc.confirm).toHaveBeenCalled();
            expect(modalInstance.close).toHaveBeenCalled();
        });
        it('should call alert when there is error', function() {
            var c = controller();
            var response = {
                data: {
                    result: {}
                }
            };
            response.data.result = {
                result: 'error'
            };
            c.afterSave(response);

            expect(notificationSvc.alert).toHaveBeenCalled();
        });
    });
    describe('afterSaveError', function() {
        it('should call alert', function() {
            var c = controller();
            var response = {
                data: {
                    errors: {}
                }
            };
            c.afterSaveError(response);

            expect(notificationSvc.alert).toHaveBeenCalledWith({
                message: 'modal.alert.unsavedchanges',
                errors: _.where(response.data.errors, {
                    field: null
                })
            });
        });
    });
});