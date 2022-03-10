namespace inprotech.configuration.general.events.eventnotetypes {
    describe('inprotech.configuration.general.events.eventnotetypes.EventNoteTypesMaintenanceController', () => {
        'use strict';

        let controller: (options?) => EventNoteTypesMaintenanceController,
            EventNoteTypesService: IEventNoteTypesService, notificationSvc: any, uibModalInstance: any,
            entityStates: any, modalService: any, hotkeys: any, form: ng.IFormController;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.events.eventnotetypes');

            form = jasmine.createSpyObj('ng.IFormController', ['$pristine', '$invalid', '$dirty', '$validate', '$setPristine']);

            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks.configuration.general.events.eventnotetypes', 'inprotech.mocks', 'inprotech.mocks.components.notification']);

                notificationSvc = $injector.get('notificationServiceMock');
                $provide.value('notificationService', notificationSvc);

                EventNoteTypesService = $injector.get<IEventNoteTypesService>('EventNoteTypesServiceMock');
                $provide.value('eventNoteTypesService', EventNoteTypesService);

                uibModalInstance = $injector.get('ModalInstanceMock');
                $provide.value('$uibModalInstance', uibModalInstance);

                modalService = $injector.get('modalServiceMock');
                $provide.value('modalService', modalService);

                hotkeys = $injector.get('hotkeysMock');
                $provide.value('hotkeys', hotkeys);
            });
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService, states: any) => {
            controller = (options) => {
                if (options == null) {
                    options = {
                        id: 'EventNoteTypesMaintenance',
                        entity: {
                            state: states.normal
                        }
                    };
                }
                entityStates = states;
                return new EventNoteTypesMaintenanceController(uibModalInstance, notificationSvc, EventNoteTypesService, states, hotkeys, modalService, options);
            };
        }));
        describe('cancel', () => {
            it('should close modal instance', () => {
                let ctrl: EventNoteTypesMaintenanceController = controller();
                ctrl.cancel();

                expect(uibModalInstance.close).toHaveBeenCalled();
            });
        });
        describe('isEditState', () => {
            it('should return true when state is updating', () => {
                let ctrl: EventNoteTypesMaintenanceController = controller({
                    entity: {
                        state: entityStates.updating
                    }
                });
                expect(ctrl.isEditState()).toEqual(true);
            });
            it('should return false when state is not updating', () => {
                let ctrl: EventNoteTypesMaintenanceController = controller({
                    entity: {
                        state: entityStates.adding
                    }
                });
                expect(ctrl.isEditState()).toEqual(false);
            });
        });
        describe('dismissAll', () => {
            it('should cancel', () => {
                let ctrl: EventNoteTypesMaintenanceController = controller();
                form.$dirty = false;
                ctrl.form = form;
                spyOn(ctrl, 'cancel');

                ctrl.dismissAll();

                expect(ctrl.cancel).toHaveBeenCalled();
            });
            it('should prompt notification if there are any unsaved changes', () => {
                let ctrl = controller();
                form.$dirty = true;
                ctrl.form = form;

                ctrl.dismissAll();

                expect(notificationSvc.discard).toHaveBeenCalled();
            });
            it('should close modal dialog when discard button is clicked', () => {
                let ctrl = controller();
                form.$dirty = true;
                ctrl.form = form;
                spyOn(ctrl, 'cancel');
                notificationSvc.discard.confirmed = true;
                ctrl.dismissAll();

                expect(ctrl.cancel).toHaveBeenCalled();
            });
        });
        describe('save', () => {
            it('should add entity', () => {
                let ctrl = controller({
                    entity: {
                        state: 'adding'
                    },
                    callbackFn: angular.noop
                });
                form.$invalid = false;
                ctrl.form = form;

                ctrl.save();
                expect(uibModalInstance.close).toHaveBeenCalled();
                expect(notificationSvc.success).toHaveBeenCalled();
            });
            it('should update entity', () => {
                let ctrl = controller({
                    entity: {
                        state: 'updating'
                    },
                    callbackFn: angular.noop
                });
                form.$invalid = false;
                ctrl.form = form;

                ctrl.save();
                expect(ctrl.form.$setPristine).toHaveBeenCalled();
                expect(notificationSvc.success).toHaveBeenCalled();
            });
        });
        describe('afterSave', () => {
            it('should close modal instance', () => {
                let ctrl = controller({
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
                ctrl.afterSave(response);

                expect(EventNoteTypesService.savedEventNoteTypeIds).toEqual([1]);
                expect(uibModalInstance.close).toHaveBeenCalled();
                expect(notificationSvc.success).toHaveBeenCalled();
            });
            it('should call alert when there is error', () => {
                let ctrl = controller();
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

                ctrl.afterSave(response);

                expect(notificationSvc.alert).toHaveBeenCalledWith({
                    title: 'modal.unableToComplete',
                    message: ctrl.getError('description').topic,
                    errors: _.where(response.data.result.errors, {
                        field: null
                    })
                });
            });
        });
        describe('afterSaveError', () => {
            it('should call alert', () => {
                let ctrl = controller();
                let response = {
                    data: {
                        result: {
                            errors: null
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
}