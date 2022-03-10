namespace inprotech.configuration.general.names.locality {
    describe('inprotech.configuration.general.names.locality.LocalityMaintenanceController', () => {
        'use strict';

        let controller: (dependencies?: any) => LocalityMaintenanceController,
            notificationService: any, form: ng.IFormController, LocalityService: ILocalityService,
            uibModalInstance: any, entityStates: any, modalService: any, hotkeys: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.names.locality');

            form = jasmine.createSpyObj('ng.IFormController', ['$setPristine', '$invalid', '$dirty', '$validate']);

            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService =
                    angular.injector(['inprotech.mocks.components.notification',
                        'inprotech.mocks.configuration.rules.workflows', 'inprotech.mocks', 'ng']);
                LocalityService = $injector.get<ILocalityService>('LocalityServiceMock');
                notificationService = $injector.get('notificationServiceMock');
                uibModalInstance = $injector.get('ModalInstanceMock');
                modalService = $injector.get('modalServiceMock');
                hotkeys = $injector.get('hotkeysMock');
            });
        });

        beforeEach(inject((states: any) => {
            entityStates = states;
            controller = (options) => {
                if (options == null) {
                    options = {
                        id: 'LocalityMaintenance',
                        entity: {
                            state: states.normal
                        },
                        callbackFn: angular.noop
                    };
                }
                return new LocalityMaintenanceController(uibModalInstance, options, notificationService, states, LocalityService, hotkeys, modalService);
            };
        }));

        describe('cancel', () => {
            it('should close modal instance', () => {
                let c: LocalityMaintenanceController = controller();
                c.cancel();
                expect(uibModalInstance.close).toHaveBeenCalled();
            });
        });

        describe('isEdit', () => {
            it('should return true when state is updating', () => {
                let c: LocalityMaintenanceController = controller({
                    entity: {
                        currentState: entityStates.updating
                    }
                });
                expect(c.isEdit).toEqual(true);
            });
            it('should return false when state is not updating', () => {
                let c: LocalityMaintenanceController = controller({
                    entity: {
                        state: entityStates.adding
                    }
                });
                expect(c.isEdit).toEqual(false);
            });
        });

        describe('dismissAll', () => {
            it('should cancel', () => {
                let c: LocalityMaintenanceController = controller();
                form.$dirty = false;
                c.form = form;
                spyOn(c, 'cancel');
                c.dismissAll();

                expect(c.cancel).toHaveBeenCalled();
            });
            it('should prompt notification if there are any unsaved changes', () => {
                let c = controller();
                form.$dirty = true;
                c.form = form;
                c.dismissAll();

                expect(notificationService.discard).toHaveBeenCalled();
            });
            it('should close modal dialog when discard button is clicked', () => {
                let c = controller();
                form.$dirty = true;
                c.form = form;
                spyOn(c, 'cancel');
                notificationService.discard.confirmed = true;
                c.dismissAll();

                expect(c.cancel).toHaveBeenCalled();
            });
        });

        describe('save', () => {
            it('should add entity', () => {
                let c = controller({
                    entity: {
                        currentState: 'adding'
                    },
                    callbackFn: angular.noop
                });
                form.$invalid = false;
                c.form = form;
                c.save();

                expect(uibModalInstance.close).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
            });
            it('should update entity', () => {
                let c = controller({
                    entity: {
                        currentState: 'updating'
                    },
                    callbackFn: angular.noop
                });
                form.$invalid = false;
                c.form = form;
                c.save();

                expect(c.form.$setPristine).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
            });
        });

        describe('afterSave', () => {
            it('should close modal instance', () => {
                let c = controller({
                    entity: {
                        id: null,
                        state: 'adding'
                    },
                    callbackFn: angular.noop
                });
                let response = {
                    data: {
                        result: {
                            result: 'success',
                            updatedId: 1
                        }
                    }
                };
                c.afterSave(response);

                expect(LocalityService.savedIds).toEqual([1]);
                expect(uibModalInstance.close).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
            });
            it('should call alert when there is error', () => {
                let c = controller();
                let response = {
                    data: {
                        result: {
                            errors: [{
                                id: null,
                                field: 'description',
                                topic: 'error',
                                message: 'field.errors.notunique'
                            }]
                        }
                    }
                };
                c.afterSave(response);

                expect(notificationService.alert).toHaveBeenCalledWith({
                    title: 'modal.unableToComplete',
                    message: c.getError('description').topic,
                    errors: _.where(response.data.result.errors, {
                        field: null
                    })
                });
            });
        });

        describe('afterSaveError', () => {
            it('should call alert', () => {
                let c = controller();
                let response = {
                    data: {
                        result: {
                            errors: null
                        }
                    }
                };
                c.afterSaveError(response);

                expect(notificationService.alert).toHaveBeenCalledWith({
                    message: 'modal.alert.unsavedchanges',
                    errors: _.where(response.data.result.errors, {
                        field: null
                    })
                });
            });
        });
    });
}
