describe('inprotech.configuration.rules.workflows.ipMaintainCharacteristics', function() {
    'use strict';

    var controller, charsService, mainService, extObjFactory, caseValidCombinationService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module('inprotech.configuration.general.validcombination');

        module(function() {
            caseValidCombinationService = test.mock('caseValidCombinationService');
            charsService = test.mock('workflowsCharacteristicsService');
            mainService = test.mock('workflowsMaintenanceService');
            mainService.getCharacteristics.returnValue = [];
        });

        inject(function($controller) {
            var $injector = angular.injector(['inprotech.mocks.configuration.rules.workflows', 'inprotech.core.extensible']);

            extObjFactory = $injector.get('ExtObjFactory');

            var defaultTopicParams = {
                criteriaId: 1,
                canEdit: true,
                hasOffices: true
            };

            controller = function(topicParams) {
                var c = $controller('ipMaintainCharacteristicsController', {
                    ExtObjFactory: extObjFactory,
                    workflowsMaintenanceService: mainService,
                    workflowsCharacteristicsService: charsService
                }, {
                    topic: {
                        params: _.extend(defaultTopicParams, topicParams)
                    }
                });
                c.$onInit();
                return c;
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
        expect(c.topic.hasError).toBeDefined();
        expect(c.topic.getFormData).toBeDefined();
        expect(c.topic.isDirty).toBeDefined();
        expect(c.topic.discard).toBeDefined();
        expect(c.topic.afterSave).toBeDefined();
        expect(mainService.getCharacteristics).toHaveBeenCalledWith(1);
        expect(c.topic.initialised).toBe(true);
        expect(charsService.setValidation).toHaveBeenCalled();
        expect(c.caseTypeChanged).toBeDefined();
        
        expect(c.showExaminationType).toBe(charsService.showExaminationType);
        expect(c.showRenewalType).toBe(charsService.showRenewalType);
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

    it('validate should call service', function() {
        var c = controller();
        c.validate();
        expect(charsService.validate).toHaveBeenCalledWith(c.formData, c.form);
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
        return c.topic.hasError();
    }

    it('getFormData should call service', function() {
        var c = controller();
        c.topic.getFormData();
        expect(mainService.createSaveRequestDataForCharacteristics).toHaveBeenCalled();
    });

    describe('after save', function() {
        it('repopulates form data with data returned from server and resets disableProtectedRadioButtons flag', function() {
            var c = controller();
            c.formData = {
                isEditProtectionBlockedByParent: true
            };

            c.topic.afterSave({
                isEditProtectionBlockedByParent: false
            });

            expect(c.formData.isEditProtectionBlockedByParent).toBe(false);
            expect(c.disableProtectedRadioButtons).toBe(true);
        });
    });

    describe('enabling and disabling protected radio buttons', function() {
        describe('enabling protected radio buttons', function() {
            it('enables when criteria is editable and not blocked ', function() {
                mainService.getCharacteristics.returnValue = {
                    isEditProtectionBlockedByParent: false,
                    isEditProtectionBlockedByDescendants: false
                };
                var c = controller({
                    canEdit: true,
                    canEditProtected: true
                });

                expect(c.disableProtectedRadioButtons).toBe(false);
                expect(c.protectionDisabledText).toBeUndefined();
            });
        });

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

            it('disables when criteria is unprotected and parent is unprotected', function() {
                mainService.getCharacteristics.returnValue = {
                    isEditProtectionBlockedByParent: true
                };
                var c = controller();

                expect(c.disableProtectedRadioButtons).toBe(true);
                expect(c.protectionDisabledText).toBe('workflows.maintenance.isUnprotectedWithUnprotectedParent');
            });

            it('disables when criteria is protected and child is protected', function() {
                mainService.getCharacteristics.returnValue = {
                    isEditProtectionBlockedByDescendants: true
                };
                var c = controller();

                expect(c.disableProtectedRadioButtons).toBe(true);
                expect(c.protectionDisabledText).toBe('workflows.maintenance.isProtectedWithProtectedChild');
            });
        });
    });
});