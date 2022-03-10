namespace inprotech.configuration.general.ede.datamapping {
    describe('inprotech.configuration.general.ede.datamapping', () => {
        'use strict';

        let controller: (dependencies?: any) => DataMappingMaintenanceController,
            notificationService: any, form: ng.IFormController, DataMappingService: IDataMappingService,
            uibModalInstance: any, entityStates: any, modalService: any, hotkeys: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.ede.datamapping');

            form = jasmine.createSpyObj('ng.IFormController', ['$setPristine', '$invalid', '$dirty', '$validate']);

            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService =
                    angular.injector(['inprotech.mocks.components.notification',
                        'inprotech.mocks.configuration.rules.workflows', 'inprotech.mocks', 'ng']);
                DataMappingService = $injector.get<IDataMappingService>('DataMappingServiceMock');
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
                        id: 'DataMappingMaintenance',
                        entity: {
                            state: states.normal
                        },
                        callbackFn: angular.noop,
                        structure: 'Documents'
                    };
                }
                return new DataMappingMaintenanceController(uibModalInstance, options, states, DataMappingService, notificationService, modalService, hotkeys);
            };
        }));

        describe('cancel', () => {
            it('should close modal instance', () => {
                let c: DataMappingMaintenanceController = controller();
                c.cancel();
                expect(uibModalInstance.close).toHaveBeenCalled();
            });
        });

        describe('isEdit', () => {
            it('should return true when state is updating', () => {
                let c: DataMappingMaintenanceController = controller({
                    entity: {
                        state: entityStates.updating
                    },
                    structure: 'Documents'
                });
                expect(c.isEdit).toEqual(true);
            });
            it('should return false when state is not updating', () => {
                let c: DataMappingMaintenanceController = controller({
                    entity: {
                        state: entityStates.adding
                    },
                    structure: 'Documents'
                });
                expect(c.isEdit).toEqual(false);
            });
        });

        describe('dismissAll', () => {
            it('should cancel', () => {
                let c: DataMappingMaintenanceController = controller();
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
                        state: 'adding',
                        event: {
                            key: -312,
                            code: 'Filing Event',
                            description: 'Filing Description'
                        }
                    },
                    callbackFn: angular.noop,
                    structure: 'Documents'
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
                        state: 'updating',
                        event: {
                            key: -312,
                            code: 'Filing Event',
                            description: 'Filing Description'
                        }
                    },
                    callbackFn: angular.noop,
                    structure: 'Documents'
                });
                form.$invalid = false;
                c.form = form;
                c.save();

                expect(c.form.$setPristine).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
            });
        });
    });
}
