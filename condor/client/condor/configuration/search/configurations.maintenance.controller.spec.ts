namespace inprotech.configuration.search {

    describe('inprotech.configuration.search.ConfigurationItemMaintenanceController', () => {
        'use strict';

        let controller: (dependencies ?: any) => ConfigurationItemMaintenanceController,
            configurationsService: IConfigurationsService,
            notificationSvc: any, uibModalInstance: any,
            entityStates: any, modalService: any, hotkeys: any, form: ng.IFormController;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.search');

            form = jasmine.createSpyObj('ng.IFormController', ['$pristine', '$invalid', '$dirty', '$validate', '$setPristine']);

            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.search', 'inprotech.mocks.components.notification']);

                configurationsService = $injector.get < IConfigurationsService > ('ConfigurationsServiceMock');

                notificationSvc = $injector.get('notificationServiceMock');
                $provide.value('notificationService', notificationSvc);

                uibModalInstance = $injector.get('ModalInstanceMock');
                $provide.value('$uibModalInstance', uibModalInstance);

                modalService = $injector.get('modalServiceMock');
                $provide.value('modalService', modalService);

                hotkeys = $injector.get('hotkeysMock');
                $provide.value('hotkeys', hotkeys);
                modalService = $injector.get('modalServiceMock');
            });
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService, states: any) => {
            controller = (options) => {
                let entity = {
                    state: states.normal
                };

                let o = options || {
                        id: 'ConfigurationItemMaintenance',
                        allItems: [entity],
                        dataItem: entity,
                        entity: entity
                    };

                entityStates = states;
                return new ConfigurationItemMaintenanceController(uibModalInstance, notificationSvc, configurationsService, states, hotkeys, modalService, o);
            };
        }));
        describe('cancel', () => {
            it('should close modal instance', () => {
                let ctrl: ConfigurationItemMaintenanceController = controller();
                ctrl.cancel();

                expect(uibModalInstance.close).toHaveBeenCalled();
            });
        });
        describe('isEditState', () => {
            it('should return true when state is updating', () => {
                let entity = {
                    state: entityStates.updating
                };

                let ctrl: ConfigurationItemMaintenanceController = controller({
                    dataItem: entity,
                    entity: entity
                });
                expect(ctrl.isEditState()).toEqual(true);
            });
        });
        describe('dismissAll', () => {
            it('should cancel', () => {
                let ctrl: ConfigurationItemMaintenanceController = controller();
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
            it('should update entity', () => {
                let entity = {
                    rowKey: 123,
                    state: 'updating'
                };
                let ctrl = controller({
                    entity: entity,
                    dataItem: entity,
                    allItems: [entity],
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
            it('should notify success', () => {
                let entity = {
                    id: 1,
                    rowKey: 123,
                    state: 'updating'
                };
                let ctrl = controller({
                    entity: entity,
                    dataItem: entity,
                    allItems: [entity],
                    callbackFn: angular.noop
                });
                let response = {
                    data: [1]
                };
                ctrl.form = form;
                ctrl.afterSave(response);

                expect(notificationSvc.success).toHaveBeenCalled();
            });
        });
        describe('afterSaveError', () => {
            it('should call alert', () => {
                controller().afterSaveError({});
                expect(notificationSvc.alert).toHaveBeenCalledWith({
                    message: 'modal.alert.unsavedchanges'
                });
            });
        });
    });
}