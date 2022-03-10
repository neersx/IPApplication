describe('inprotech.configuration.general.jurisdictions.ValidNumbersMaintenanceController', () => {
    'use strict';

    let controller: (dependencies?: any) => ValidNumbersMaintenanceController,
        notificationService: any, form: ng.IFormController,
        maintenanceModalService: any, caseValidCombinationService: any,
        workflowEntryControlService: any, modalOptions: any,
        scope: ng.IScope, uibModalInstance: any, dateHelper: any, jurisdictionValidNumbersService: any, modalService: any;

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
            jurisdictionValidNumbersService = $injector.get('JurisdictionValidNumbersServiceMock');
            modalService = $injector.get('modalServiceMock');
        });
    });

    beforeEach(inject(($rootScope: ng.IRootScopeService, utils: any, $translate: any) => {
        scope = <ng.IScope>$rootScope.$new();
        modalOptions = {
            id: 'ValidNumbersMaintenance',
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
            return new ValidNumbersMaintenanceController(scope, uibModalInstance,
                dependencies.options, maintenanceModalService, caseValidCombinationService, dateHelper,
                workflowEntryControlService, jurisdictionValidNumbersService, notificationService, $translate, modalService);
        };
    }));

    describe('initialization and form controls state', () => {
        let c: ValidNumbersMaintenanceController;

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

    describe('Test number pattern', function () {
        it('should call test number pattern modalService', function () {
            let c = controller();
            c.onTestPatternClick();

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'ValidnumbersTestpattern',
                    controllerAs: 'vm',
                    bindToController: true,
                    pattern: null
                })));
        });
    });

    describe('apply changes', () => {
        let c: ValidNumbersMaintenanceController;
        beforeEach(() => {
            c = controller();
            c.formData = {
                numberType: {
                    code: 'A',
                    value: 'Property'
                },
                propertyType: {
                    code: 'P',
                    value: 'Application No'
                },
                additionalValidation: undefined,
                subType: undefined,
                caseType: undefined,
                caseCategory: undefined,
                pattern: undefined,
                displayMessage: undefined,
                warningFlag: true,
                validFrom: null,
                jurisdiction: null
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
            c.formData.validFrom = new Date(2017, 10, 5);
            c.formData.jurisdiction = 'AF';
            c.formData.propertyType.code = 'P';
            c.formData.propertyType.value = 'Property';
            c.formData.numberType.code = 'A';
            c.formData.numberType.value = 'Application No';
            c.formData.displayMessage = 'Error';
            c.formData.pattern = 'abcd';

            c.apply(undefined);

            expect(c.maintModalService.applyChanges).toHaveBeenCalled();
        });
    });
});