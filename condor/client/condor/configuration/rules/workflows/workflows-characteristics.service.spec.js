describe('inprotech.configuration.rules.workflows.workflowsCharacteristicsService', function() {
    'use strict';

    var service, formData, form, characteristicsBuilder, characteristicsValidator, sharedService, workflowsSearchService, caseValidCombinationService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module('inprotech.configuration.general.validcombination');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.rules.workflows', 'inprotech.mocks']);

            characteristicsBuilder = $injector.get('characteristicsBuilderMock');
            $provide.value('characteristicsBuilder', characteristicsBuilder);
            sharedService = {
                hasOffices: function() {
                    return;
                }
            };
            $provide.value('sharedService', sharedService);

            workflowsSearchService = $injector.get('workflowsSearchServiceMock');
            $provide.value('workflowsSearchService', workflowsSearchService);

            caseValidCombinationService = $injector.get('caseValidCombinationServiceMock');
            $provide.value('caseValidCombinationService', caseValidCombinationService)

            characteristicsValidator = {
                validate: function() {
                    return {
                        then: function(cb) {
                            if (cb) {
                                cb(characteristicsValidator.validate.returnValue || []);
                            }
                        }
                    };
                }
            };
            spyOn(characteristicsValidator, 'validate').and.callThrough();
            $provide.value('characteristicsValidator', characteristicsValidator);
        });

        inject(function(workflowsCharacteristicsService) {
            service = workflowsCharacteristicsService;

            formData = {};
            form = {};
        });
    });

    describe('characteristics validation', function() {

        _.debounce = function(func) {
            return function() {
                func.apply(this, arguments);
            };
        };

        it('should build characteristics validation request', function() {
            characteristicsBuilder.build.returnValue = 1;

            service.validate(formData, form);

            expect(characteristicsBuilder.build).toHaveBeenCalledWith(formData);
            expect(characteristicsValidator.validate).toHaveBeenCalledWith(characteristicsBuilder.build.returnValue, jasmine.any(Function));
        });

        describe('setValidity method', function() {
            var validationResults;
            beforeEach(function() {
                validationResults = {
                    office: {
                        isValid: null,
                        value: 'OfficeDescription'
                    }
                };
                form = {
                    office: {
                        $setText: function() {
                            return;
                        },
                        $setValidity: function() {
                            return;
                        },
                        $$attr: {
                            disabled: false
                        }
                    }
                };
                spyOn(form.office, '$setText');
                spyOn(form.office, '$setValidity');
            });

            it('sets new valid description and resets validity when valid', function() {
                validationResults.office.isValid = true;
                service.setValidation(validationResults, form);

                expect(form.office.$setText).toHaveBeenCalledWith(validationResults.office.value);
                expect(form.office.$setValidity).toHaveBeenCalledWith('invalidcombination', null);
            });

            it('resets validity if not valid', function() {
                validationResults.office.isValid = false;
                service.setValidation(validationResults, form);

                expect(form.office.$setValidity).toHaveBeenCalledWith('invalidcombination', false);
                expect(form.office.$setText).not.toHaveBeenCalled();
            });

            it('should not set validity if control is disabled', function() {
                form.office.$$attr.disabled = true;

                validationResults.office.isValid = false;
                service.setValidation(validationResults, form);

                expect(form.office.$setValidity).toHaveBeenCalledWith('invalidcombination', null);
                expect(form.office.$setText).not.toHaveBeenCalled();
            });
        });
    });

    describe('Examination and Renewal Type', function() {
        it('shows examination type when examination action', function() {
            var formData = {
                action: {
                    actionType: 'examination'
                }
            };

            var r = service.showExaminationType(formData);

            expect(r).toEqual(true);

            r = service.showRenewalType(formData);
            expect(r).toEqual(false);
        });

        it('shows renewal type when renewal action', function() {
            var formData = {
                action: {
                    actionType: 'renewal'
                }
            };

            var r = service.showRenewalType(formData);

            expect(r).toEqual(true);

            r = service.showExaminationType(formData);
            expect(r).toEqual(false);
        });
    });

    describe('Initialise controllers', function() {
        it('Initialises common controller data and methods', function() {
            var c = {};
            var name = 'controllerName';
            formData = { a: 'a' };

            service.initController(c, name, formData);

            expect(c.formData).toBe(formData);
            expect(c.validate).toBeDefined();
            expect(c.extendPicklistQuery).toBe(caseValidCombinationService.extendValidCombinationPickList);
            expect(c.isDateOfLawDisabled).toBe(caseValidCombinationService.isDateOfLawDisabled);
            expect(c.isCaseCategoryDisabled).toBe(caseValidCombinationService.isCaseCategoryDisabled);
            expect(c.hasOffices).toBeDefined();
            expect(c.picklistValidCombination).toBe(caseValidCombinationService.validCombinationDescriptionsMap);
            expect(c.showExaminationType).toBeDefined();
            expect(c.showRenewalType).toBeDefined();
        });

        it('Initialises sharedServices by name', function() {
            var c = {};
            var name = 'controllerName';
            formData = { a: 'a' };

            service.initController(c, name, formData);

            expect(sharedService.controllerName.defaultFormData).not.toBe(formData);
            expect(sharedService.controllerName.defaultFormData).toEqual(formData);
            expect(sharedService.controllerName.search).toBeDefined();
            expect(sharedService.controllerName.reset).toBeDefined();
            expect(sharedService.controllerName.isSearchDisabled).toBeDefined();
            expect(sharedService.controllerName.characteristicsSelected).toBeDefined();
        });
    });

    describe('Shared service methods', function() {
        var c;
        beforeEach(function() {
            c = {};
            formData = {
                applyTo: null,
                a: 'a'
            };
            service.initController(c, 'controllerName', formData);
        });

        it('forwards correct parameters to search', function() {
            c.formData = 'form';
            c.form = {
                $validate: angular.noop,
                $invalid: false
            };
            sharedService.controllerName.search('query');
            expect(workflowsSearchService.search).toHaveBeenCalledWith('form', 'query');
        });

        it('should not do search', function() {
            c.formData = 'form';
            c.form = {
                $validate: angular.noop,
                $invalid: true
            };
            sharedService.controllerName.search('query');
            expect(workflowsSearchService.search).not.toHaveBeenCalled();
        });

        it('disables search if loading or invalid', function() {
            expect(searchDisabledCheck(c, true, true)).toBe(true);
            expect(searchDisabledCheck(c, true, false)).toBe(true);
            expect(searchDisabledCheck(c, false, true)).toBe(true);
            expect(searchDisabledCheck(c, false, false)).toBe(false);
        });

        function searchDisabledCheck(cont, loading, invalid) {
            cont.form = {
                $loading: loading,
                $invalid: invalid
            };
            return sharedService.controllerName.isSearchDisabled();
        }

        it('call to characteristicsSelected, should return selected valid charecteristics data', function() {
            c.formData = {
                applyTo: 'foreign-client',
                action: 'action1',
                basis: 'basis1',
                caseCategory: 'caseCategory',
                caseType: 'caseType',
                dateOfLaw: 'dateOfLaw',
                jurisdiction: 'jurisdiction1',
                office: 'office1',
                propertyType: 'propertyType1',
                subType: 'subType1',
                examinationType: 'examinationType1',
                renewalType: 'renewalType1'
            };

            var valid = { $valid: true };
            var invalid = { $valid: false };

            c.form = {
                action: valid,
                basis: valid,
                caseCategory: valid,
                caseType: valid,
                dateOfLaw: invalid,
                jurisdiction: valid,
                office: invalid,
                propertyType: valid,
                subType: valid,
                examinationType: valid,
                renewalType: valid
            };

            var r = sharedService.controllerName.characteristicsSelected();

            expect(r.isLocalClient).toBeFalsy();
            expect(r.action).toBe(c.formData.action);
            expect(r.basis).toBe(c.formData.basis);
            expect(r.caseCategory).toBe(c.formData.caseCategory);
            expect(r.caseType).toBe(c.formData.caseType);
            expect(r.jurisdiction).toBe(c.formData.jurisdiction);
            expect(r.propertyType).toBe(c.formData.propertyType);
            expect(r.subType).toBe(c.formData.subType);
            expect(r.examinationType).toBe(c.formData.examinationType);
            expect(r.renewalType).toBe(c.formData.renewalType);

            expect(r.dateOfLaw).not.toBeDefined();
            expect(r.office).not.toBeDefined();
        });
    });
});
