describe('inprotech.configuration.general.jurisdictions.ChangeJurisdictionCodeController', () => {
    'use strict';

    let controller: (dependencies?: any) => ChangeJurisdictionCodeController,
        notificationService: any, jurisdictionMaintenanceSvc: any, uibModalInstance: any, hotkeys: any, modalService: any, form: ng.IFormController;

    beforeEach(() => {
        angular.mock.module('inprotech.configuration.general.jurisdictions');

        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService =
                angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks', 'inprotech.mocks.components.notification']);

            form = jasmine.createSpyObj('ng.IFormController', ['$setPristine', '$invalid', '$dirty', '$validate']);

            notificationService = $injector.get('notificationServiceMock');
            jurisdictionMaintenanceSvc = $injector.get('JurisdictionMaintenanceServiceMock');
            uibModalInstance = $injector.get('ModalInstanceMock');
            hotkeys = $injector.get('hotkeysMock');
            modalService = $injector.get('modalServiceMock');
        });
    });

    beforeEach(inject(() => {

        controller = (options) => {
            if (options == null) {
                options = {
                    id: 'ChangeJurisdictionCode',
                    entity: {},
                    controllerAs: 'vm'
                };
            }

            return new ChangeJurisdictionCodeController(uibModalInstance, notificationService,
                jurisdictionMaintenanceSvc, hotkeys, modalService, options)
        };
    }));

    describe('cancel', () => {
        it('should close modal instance', () => {
            let ctrl: ChangeJurisdictionCodeController = controller();
            ctrl.cancel();

            expect(uibModalInstance.dismiss).toHaveBeenCalled();
        });
    });

    describe('dismissAll', () => {
        it('should cancel', () => {
            let ctrl = controller();
            form.$dirty = false;
            ctrl.changeCodeForm = form;

            spyOn(ctrl, 'cancel');
            ctrl.dismissAll();

            expect(ctrl.cancel).toHaveBeenCalled();
        });
        it('should prompt notification if there are any unsaved changes', () => {
            let ctrl = controller();
            form.$dirty = true;
            ctrl.changeCodeForm = form;

            ctrl.dismissAll();

            expect(notificationService.discard).toHaveBeenCalled();
        });
        it('should close modal dialog when discard button is clicked', () => {
            let ctrl = controller();
            form.$dirty = true;
            ctrl.changeCodeForm = form;
            notificationService.discard.confirmed = true;
            spyOn(ctrl, 'cancel');

            ctrl.dismissAll();

            expect(ctrl.cancel).toHaveBeenCalled();
        });
    });

    describe('save', function () {
        it('should call notificationService if entity is invalid', () => {
            let ctrl = controller();
            form.$invalid = true;
            ctrl.changeCodeForm = form;

            ctrl.save();

            expect(notificationService.alert).toHaveBeenCalledWith({
                title: 'modal.unableToComplete',
                message: 'modal.alert.unsavedchanges'
            });
        });
        it('should ask for confirmation for change of jurisdiction code', () => {
            let ctrl = controller({
                entity: {
                    jurisdictionCode: 'C',
                    newJurisdictionCode: 'Z'
                }
            });
            form.$invalid = false;
            ctrl.changeCodeForm = form;

            ctrl.save();

            expect(notificationService.confirm).toHaveBeenCalled();
            expect(jurisdictionMaintenanceSvc.changeJurisdictionCode).toHaveBeenCalled();
        });
    });
});