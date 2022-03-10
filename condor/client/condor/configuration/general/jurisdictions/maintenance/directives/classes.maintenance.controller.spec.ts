describe('inprotech.configuration.general.jurisdictions.ClassesMaintenanceController', () => {
    'use strict';

    let controller: (dependencies?: any) => ClassesMaintenanceController,
        notificationService: any, form: ng.IFormController,
        maintenanceModalService: any, caseValidCombinationService: any,
        workflowEntryControlService: any, modalOptions: any,
        scope: ng.IScope, uibModalInstance: any, dateHelper: any;

    beforeEach(() => {
        angular.mock.module('inprotech.configuration.general.jurisdictions');

        form = jasmine.createSpyObj('ng.IFormController', ['$pristine', '$invalid', '$dirty', '$validate']);

        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService =
                angular.injector(['inprotech.mocks.components.notification',
                    'inprotech.mocks.configuration.rules.workflows', 'inprotech.mocks', 'ng']);

            notificationService = $injector.get('notificationServiceMock');
            workflowEntryControlService = $injector.get('workflowsEntryControlServiceMock');
            caseValidCombinationService = $injector.get('caseValidCombinationServiceMock');
            uibModalInstance = $injector.get('ModalInstanceMock');
            maintenanceModalService = $injector.get('maintenanceModalServiceMock');
        });
    });

    beforeEach(inject(($rootScope: ng.IRootScopeService, utils: any, $translate: any) => {
        scope = <ng.IScope>$rootScope.$new();
        modalOptions = {
            id: 'ClassesMaintenance',
            mode: '',
            isAddAnother: false,
            addItem: angular.noop,
            allItems: [],
            controllerAs: 'vm',
            dataItem: undefined,
            parentId: '',
            jurisdiction: ''
        };
        controller = function (dependencies) {
            dependencies = _.extend(
                {
                    options: modalOptions
                }, dependencies);
            return new ClassesMaintenanceController(scope, uibModalInstance,
                dependencies.options, maintenanceModalService, caseValidCombinationService, dateHelper,
                workflowEntryControlService, notificationService, $translate);
        };
    }));

    describe('initialization and form controls state', () => {
        let c: ClassesMaintenanceController;

        it('should initialise variables', () => {
            modalOptions.isAddAnother = true;
            c = controller(modalOptions);

            expect(c.isAddAnother).toBe(modalOptions.isAddAnother);
        });

        it('Apply is enabled when form is dirty and valid', () => {
            c = controller();

            form.$pristine = false;
            form.$invalid = false;
            c.form = form;

            expect(c.isApplyEnabled()).toBe(true);
        });

        it('has unsaved changes when form is dirty', () => {
            c = controller();

            form.$dirty = true;
            c.form = form;

            expect(c.hasUnsavedChanges()).toBe(true);
        });

        it('should close the modal', () => {
            c = controller();

            c.dismiss();

            expect(uibModalInstance.dismiss).toHaveBeenCalled();
        });
    });

    describe('apply changes', () => {
        let c: ClassesMaintenanceController;
        beforeEach(() => {
            c = controller();
            c.formData = {
                class: undefined,
                description: '',
                subClass: undefined,
                notes: undefined,
                effectiveDate: null,
                propertyTypeModel: {
                    code: 'P',
                    value: 'Property'
                }
            };
        })

        it('should not apply changes when form is invalid', () => {
            (form.$validate as jasmine.Spy).and.returnValue(false);

            c.form = form;
            c.apply(undefined);

            expect(workflowEntryControlService.isDuplicated).not.toHaveBeenCalled();
        });
        it('should call notification alert when duplicate entry is entered', () => {
            (form.$validate as jasmine.Spy).and.returnValue(true);
            (workflowEntryControlService.isDuplicated as jasmine.Spy).and.returnValue(true);

            c.form = form;
            c.apply(undefined);

            expect(notificationService.alert).toHaveBeenCalled();
        });
        it('should apply changes when all validations are fulfilled', () => {
            (form.$validate as jasmine.Spy).and.returnValue(true);
            (workflowEntryControlService.isDuplicated as jasmine.Spy).and.returnValue(false);

            c.form = form;
            c.formData.class = '01';
            c.formData.description = 'Test Description';
            c.formData.effectiveDate = new Date(2017, 10, 5);
            c.formData.jurisdiction = 'AF',
                c.formData.subClass = 'Test Sub Class';
            c.formData.propertyTypeModel.code = 'P';
            c.formData.propertyTypeModel.value = 'Property';
            c.formData.propertyTypeModel.allowSubClass = true;

            c.apply(undefined);

            expect(c.maintModalService.applyChanges).toHaveBeenCalled();
        });
    });
});