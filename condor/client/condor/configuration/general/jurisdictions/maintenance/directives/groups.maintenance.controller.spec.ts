describe('inprotech.configuration.general.jurisdictions.GroupMembershipMaintenanceController', () => {
    'use strict';

    let controller: (dependencies?: any) => GroupMembershipMaintenanceController,
        notificationService: any, form: ng.IFormController,
        maintenanceModalService: any, workflowEntryControlService: any,
        modalOptions: IGroupModalOptions, scope: ng.IScope, uibModalInstance: any,
        dateHelper: any, caseValidCombinationService: any;

    beforeEach(() => {
        angular.mock.module('inprotech.configuration.general.jurisdictions');

        form = jasmine.createSpyObj('ng.IFormController', ['$pristine', '$invalid', '$dirty', '$validate']);

        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService =
                angular.injector(['inprotech.mocks.components.notification',
                    'inprotech.mocks.configuration.rules.workflows', 'inprotech.mocks', 'ng']);

            notificationService = $injector.get('notificationServiceMock');
            workflowEntryControlService = $injector.get('workflowsEntryControlServiceMock');
            uibModalInstance = $injector.get('ModalInstanceMock');
            caseValidCombinationService = $injector.get('caseValidCombinationServiceMock');
            maintenanceModalService = $injector.get('maintenanceModalServiceMock');
        });
    });

    beforeEach(inject(($rootScope: ng.IRootScopeService, utils: any, $translate: any) => {
        scope = <ng.IScope>$rootScope.$new();
        modalOptions = {
            id: 'GroupMembershipMaintenance',
            mode: '',
            isAddAnother: false,
            isGroup: true,
            addItem: angular.noop,
            allItems: [],
            controllerAs: 'vm',
            dataItem: undefined,
            parentId: '',
            jurisdiction: '',
            type: ''
        };
        controller = function (dependencies) {
            dependencies = _.extend(
                {
                    options: modalOptions
                }, dependencies);
            return new GroupMembershipMaintenanceController(scope, uibModalInstance,
                dependencies.options, maintenanceModalService, notificationService, $translate, utils,
                workflowEntryControlService, dateHelper, caseValidCombinationService);
        };
    }));

    describe('initialization and form controls state', () => {
        let c: GroupMembershipMaintenanceController;

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
        let c: GroupMembershipMaintenanceController;
        beforeEach(() => {
            c = controller();
            c.formData = {
                group: undefined,
                dateCeased: null,
                dateCommenced: null,
                isAssociateMember: false,
                isGroupDefault: false,
                fullMembershipDate: null,
                preventNationalPhase: false
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
        it('should call notification alert when cease date is less than joining date', () => {
            (form.$validate as jasmine.Spy).and.returnValue(true);
            (workflowEntryControlService.isDuplicated as jasmine.Spy).and.returnValue(true);

            c.form = form;

            c.formData.dateCeased = new Date(2017, 10, 1);
            c.formData.dateCommenced = new Date(2017, 10, 2)

            c.apply(undefined);

            expect(notificationService.alert).toHaveBeenCalled();
        });
        it('should call notification alert when full membership date is less than joining date', () => {
            (form.$validate as jasmine.Spy).and.returnValue(true);
            (workflowEntryControlService.isDuplicated as jasmine.Spy).and.returnValue(true);

            c.form = form;

            c.formData.fullMembershipDate = new Date(2017, 10, 1);
            c.formData.dateCommenced = new Date(2017, 10, 2)

            c.apply(undefined);

            expect(notificationService.alert).toHaveBeenCalled();
        });
        it('should call notification alert when cease date is less than full membership date', () => {
            (form.$validate as jasmine.Spy).and.returnValue(true);
            (workflowEntryControlService.isDuplicated as jasmine.Spy).and.returnValue(true);

            c.form = form;

            c.formData.fullMembershipDate = new Date(2017, 10, 2);
            c.formData.dateCeased = new Date(2017, 10, 1)

            c.apply(undefined);

            expect(notificationService.alert).toHaveBeenCalled();
        });
        it('should apply changes when all validations are fulfilled', () => {
            (form.$validate as jasmine.Spy).and.returnValue(true);
            (workflowEntryControlService.isDuplicated as jasmine.Spy).and.returnValue(false);

            c.form = form;

            c.formData.dateCommenced = new Date(2017, 10, 1)
            c.formData.fullMembershipDate = new Date(2017, 10, 3);
            c.formData.dateCeased = new Date(2017, 10, 5)

            c.apply(undefined);

            expect(c.maintModalService.applyChanges).toHaveBeenCalled();
        });
    });
    describe('property Type', () => {
        let c: GroupMembershipMaintenanceController;

        it('property type should be enabled for members', () => {
            modalOptions.isGroup = false;
            c = controller(modalOptions);
            expect(c.propertyTypeDisabled()).toBe(false);
        });

        it('property type should be enabled', () => {
            c = controller();
            c.formData = {
                group: {
                    key: '1'
                }
            };
            expect(c.propertyTypeDisabled()).toBe(false);
        });

        it('property type should be disabled', () => {
            c = controller();
            expect(c.propertyTypeDisabled()).toBe(true);
        });
    });
    describe('Jurisdiction Change', () => {
        let c: GroupMembershipMaintenanceController;

        it('expect jurisdiction formadata to be set', () => {
            modalOptions.isGroup = false;
            c = controller(modalOptions);
            c.formData = {
                group: {
                    key: '1',
                    value: 'India'
                }
            };
            c.onJurisdictionChange();
            expect(c.formData.jurisdiction.code).toBe('1');
            expect(c.formData.jurisdiction.value).toBe('India');
        });

        it('expect jurisdiction formadata not to be set', () => {
            c = controller();
            c.onJurisdictionChange();
            expect(c.formData.jurisdiction).toBe(undefined);
        });
    });
});