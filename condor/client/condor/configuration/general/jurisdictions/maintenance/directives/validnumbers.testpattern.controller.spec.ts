describe('inprotech.configuration.general.jurisdictions', () => {
    'use strict';

    let controller: (dependencies?: any) => ValidNumbersTestPatternController,
        notificationService: any, form: ng.IFormController,
        maintenanceModalService: any, scope: ng.IScope, uibModalInstance: any, modalOptions: any;

    beforeEach(() => {
        angular.mock.module('inprotech.configuration.general.jurisdictions');

        form = jasmine.createSpyObj('ng.IFormController', ['$pristine', '$invalid', '$dirty', '$validate']);

        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService =
                angular.injector(['inprotech.mocks.components.notification',
                    'inprotech.mocks.configuration.rules.workflows', 'inprotech.mocks', 'ng']);

            notificationService = $injector.get('notificationServiceMock');
            uibModalInstance = $injector.get('ModalInstanceMock');
            maintenanceModalService = $injector.get('maintenanceModalServiceMock');
        });
    });

    beforeEach(inject(($rootScope: ng.IRootScopeService, utils: any, $translate: any) => {
        scope = <ng.IScope>$rootScope.$new();
        modalOptions = {
            id: 'ValidnumbersTestpattern',
            controllerAs: 'vm',
            pattern: null
        };
        controller = function (dependencies) {
            dependencies = _.extend(
                {
                    options: modalOptions
                }, dependencies);
            return new ValidNumbersTestPatternController(scope, uibModalInstance,
                dependencies.options, maintenanceModalService, notificationService, $translate);
        };
    }));

    describe('initialization and form controls state', () => {
        let c: ValidNumbersTestPatternController;

        it('Apply is enabled when form is dirty and valid', () => {
            c = controller();
            form.$pristine = false;
            c.form = form;
            c.form.regexPattern = { $invalid: jasmine.createSpy() };
            c.form.regexPattern.$invalid = false;

            expect(c.isApplyEnabled()).toBe(true);
        });

        it('Apply is disabled when form is dirty and invalid', () => {
            c = controller();
            form.$pristine = false;
            c.form = form;
            c.form.regexPattern = { $invalid: jasmine.createSpy() };
            c.form.regexPattern.$invalid = true;

            expect(c.isApplyEnabled()).toBe(false);
        });

        it('has unsaved changes when regexPattern is dirty', () => {
            c = controller();
            c.form = form;
            c.form.regexPattern = { $dirty: jasmine.createSpy() };
            form.regexPattern.$dirty = true;
            expect(c.hasUnsavedChanges()).toBe(true);
        });

        it('has unsaved false changes when regexPattern is not dirty', () => {
            c = controller();
            c.form = form;
            c.form.regexPattern = { $dirty: jasmine.createSpy() };
            form.regexPattern.$dirty = false;

            expect(c.hasUnsavedChanges()).toBe(false);
        });


        it('should close the modal', () => {
            c = controller();
            c.dismiss();
            expect(uibModalInstance.close).toHaveBeenCalled();
        });

        it('should call notification success message on test pattern click button', () => {
            c = controller();
            c.formData.pattern = 'test';
            c.formData.testPatternNumber = 'test';
            c.onTestPatternClick();
            expect(notificationService.success).toHaveBeenCalled();
        });

        it('should dispaly error message on test pattern click button', () => {
            c = controller();
            c.formData.pattern = 'test';
            c.formData.testPatternNumber = 'xyz';
            c.onTestPatternClick();
            expect(c.errorPattern).toEqual('jurisdictions.maintenance.validNumbers.invalidNumber');
        });

        it('should clear error pattern on change of test pattern', () => {
            c = controller();
            c.formData.pattern = 'test';
            c.form = form;
            c.form.testPatternNumber = { $setPristine: jasmine.createSpy() };
            c.resetErrorPattern();
            expect(c.errorPattern).toEqual(null);
            expect(c.form.testPatternNumber.$setPristine).toHaveBeenCalled();
        });

        it('should enable the test pattern button', () => {
            c = controller();
            c.formData.pattern = 'test';
            c.formData.testPatternNumber = 'test';
            expect(c.shouldDisableTestPattern()).toBeFalsy();
        });

        it('should disblae the test pattern button', () => {
            c = controller();
            c.formData.pattern = 'test';
            expect(c.shouldDisableTestPattern()).toBeTruthy();
        });
    });
});