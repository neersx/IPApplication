
describe('inprotech.configuration.rules.workflows.createCharacteristics', function() {
    'use strict';

    var controller, charsService, mainService, extObjFactory, promiseMock, state, modelInstance, notificationService, caseValidCombinationService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module('inprotech.configuration.general.validcombination');

        module(function() {
            charsService = test.mock('workflowsCharacteristicsService');
            mainService = test.mock('workflowsMaintenanceService');
            modelInstance = test.mock('ModalInstance');
            notificationService = test.mock('notificationService');
            caseValidCombinationService = test.mock('caseValidCombinationService');

            state = test.mock('state');
            promiseMock = test.mock('promise');
        });
        inject(function($controller) {
            var $injector = angular.injector(['inprotech.mocks.configuration.rules.workflows', 'inprotech.core.extensible']);
            extObjFactory = $injector.get('ExtObjFactory');

            mainService.getCharacteristics.returnValue = [];

            var defaultViewData = {
                canEditProtected: true,
                canEdit: true,
                hasOffices: true,
                selectedCharacteristics: null
            };

            controller = function(viewData) {
                return $controller('CreateCharacteristicsController', {
                    viewData: _.extend(defaultViewData, viewData),
                    ExtObjFactory: extObjFactory,
                    workflowsMaintenanceService: mainService,
                    workflowsCharacteristicsService: charsService,
                    $uibModalInstance: modelInstance,
                    notificationService: notificationService,
                    state: state
                });
            };
        });
    });

    it('should initialise', function() {
        var c = controller();

        expect(c.form).toBeDefined();
        expect(c.formData).toBeDefined();
        expect(c.validate).toBeDefined();
        expect(c.fieldClasses).toBeDefined();
        expect(c.extendPicklistQuery).toBeDefined();
        expect(c.isDateOfLawDisabled).toBeDefined();
        expect(c.isCaseCategoryDisabled).toBeDefined();
        expect(c.canEdit).toBe(true);
        expect(c.hasOffices).toBe(true);
        expect(c.hasError).toBeDefined();
        expect(c.getFormData).toBeDefined();
        expect(c.isDirty).toBeDefined();
        expect(c.discard).toBeDefined();
        expect(c.save).toBeDefined();
        expect(c.isSaveEnabled).toBeDefined();
        expect(c.resetNameError).toBeDefined();
        expect(c.initShortcuts).toBeDefined();
        expect(c.caseTypeChanged).toBeDefined();

        expect(c.showExaminationType).toBe(charsService.showExaminationType);
        expect(c.showRenewalType).toBe(charsService.showRenewalType);

        expect(c.formData.isProtected).toBeFalsy();
    });

    it('should initialise display data from passed chacateristics', function() {
        var office = { key: 1, value: 'office1' };
        var caseType = { key: 2, value: 'caseType' };
        var jurisdiction = { key: 'AU', code: 'AU', value: 'Australia' };
        var propertyType = { key: 'p1', value: 'peroperty 1' };
        var action = { key: 15, code: 'action 1' }
        var basis = { key: 2, code: 'Y', value: "Convention" };
        var caseCategory = { key: 2, code: 'Y', value: 'Some Category' };
        var dateOfLaw = { key: 22, code: '1/01/1800 12:00:00 AM' };

        var c = controller({
            selectedCharacteristics: {
                isLocalClient: true,
                office: office,
                caseType: caseType,
                jurisdiction: jurisdiction,
                propertyType: propertyType,
                action: action,
                basis: basis,
                caseCategory: caseCategory,
                dateOfLaw: dateOfLaw
            }
        });

        expect(c.formData).toBeDefined();

        expect(c.formData.isLocalClient).toBeTruthy();
        expect(c.formData.office).toBe(office);
        expect(c.formData.caseType).toBe(caseType);
        expect(c.formData.jurisdiction).toBe(jurisdiction);
        expect(c.formData.propertyType).toBe(propertyType);
        expect(c.formData.action).toBe(action);
        expect(c.formData.basis).toBe(basis);
        expect(c.formData.caseCategory).toBe(caseCategory);
        expect(c.formData.dateOfLaw).toBe(dateOfLaw);
    });

    it('should set protected rule when negative criteria permission is available', function() {
        var c = controller({
            canCreateNegativeWorkflowRules: true
        });

        expect(c.form).toBeDefined();
        expect(c.formData).toBeDefined();
        expect(c.validate).toBeDefined();
        expect(c.fieldClasses).toBeDefined();
        expect(c.extendPicklistQuery).toBeDefined();
        expect(c.isDateOfLawDisabled).toBeDefined();
        expect(c.isCaseCategoryDisabled).toBeDefined();
        expect(c.canEdit).toBe(true);
        expect(c.hasOffices).toBe(true);
        expect(c.hasError).toBeDefined();
        expect(c.getFormData).toBeDefined();
        expect(c.isDirty).toBeDefined();
        expect(c.discard).toBeDefined();
        expect(c.save).toBeDefined();
        expect(c.isSaveEnabled).toBeDefined();
        expect(c.resetNameError).toBeDefined();
        expect(c.initShortcuts).toBeDefined();
        expect(c.caseTypeChanged).toBeDefined();

        expect(c.showExaminationType).toBe(charsService.showExaminationType);
        expect(c.showRenewalType).toBe(charsService.showRenewalType);

        expect(c.formData.isProtected).toBeTruthy();
    });

    it('validate should call service', function() {
        var c = controller();
        c.validate();
        expect(charsService.validate).toHaveBeenCalledWith(c.formData, c.form);
    });

    it('extendPicklistQuery should call service', function() {
        var c = controller();
        c.extendPicklistQuery('a');
        expect(caseValidCombinationService.extendValidCombinationPickList).toHaveBeenCalledWith('a');
    });

    it('isDateOfLawDisabled test', function() {
        var c = controller();
        caseValidCombinationService.setReturnValue('isDateOfLawDisabled', true);
        c.canEdit = true;
        expect(c.isDateOfLawDisabled()).toBe(true);
        caseValidCombinationService.setReturnValue('isDateOfLawDisabled', false);
        c.canEdit = false;
        expect(c.isDateOfLawDisabled()).toBe(true);
    });

    it('isCaseCategoryDisabled test', function() {
        var c = controller();
        c.canEdit = true;
        caseValidCombinationService.setReturnValue('isCaseCategoryDisabled', true);
        expect(c.isCaseCategoryDisabled()).toBe(true);
        caseValidCombinationService.setReturnValue('isCaseCategoryDisabled', false);
        c.canEdit = false;
        expect(c.isCaseCategoryDisabled()).toBe(true);
    });

    it('fieldClasses should build ng-class', function() {
        var c = controller();
        var r = c.fieldClasses('action');
        expect(r).toBe('{saved: vm.formData.isSaved(\'action\'), edited: vm.formData.isDirty(\'action\')}');
    });

    it('hasError should only return true if invalid and dirty', function() {
        var c = controller();
        expect(dirtyCheck(c, true, true)).toBe(true);
        expect(dirtyCheck(c, false, true)).toBe(false);
        expect(dirtyCheck(c, true, false)).toBe(false);
        expect(dirtyCheck(c, false, false)).toBe(false);
    });

    function dirtyCheck(c, invalid, dirty) {
        c.form = {
            $invalid: invalid,
            $dirty: dirty
        };
        return c.hasError();
    }

    it('getFormData should call service', function() {
        var c = controller();
        c.getFormData();
        expect(mainService.createSaveRequestDataForCharacteristics).toHaveBeenCalled();
    });

    describe('save', function() {
        it('repopulates id with data returned from server', function() {
            var c = controller();
            c.formData = {
                criteriaId: null,
                getRaw: angular.noop
            };
            c.form = {
                $valid: true
            };
            mainService.create = promiseMock.createSpy({
                data: {
                    status: true,
                    criteriaId: 1
                }
            });

            c.save();

            expect(c.formData.criteriaId).toBe(1);
        });
    });

    describe('enabling and disabling protected radio buttons', function() {

        describe('disabling protected radio buttons', function() {
            describe('user does not have rights to edit protected criteria', function() {
                it('disables for unprotected criteria', function() {
                    var c = controller({
                        canEdit: true,
                        canEditProtected: false
                    });

                    expect(c.disableProtectedRadioButtons).toBe(true);
                    expect(c.protectionDisabledText).toBeUndefined();
                });

                it('disables for protected criteria', function() {
                    var c = controller({
                        canEdit: false
                    });

                    expect(c.disableProtectedRadioButtons).toBe(true);
                    expect(c.protectionDisabledText).toBeUndefined();
                });
            });
        });
    });
});