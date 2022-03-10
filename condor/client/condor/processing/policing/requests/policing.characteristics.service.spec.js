describe('inprotech.processing.policing.policingCharacteristicsService', function() {
    'use strict';

    var service, formData, form, characteristicsBuilder, caseValidCombinationService;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.processing.policing','inprotech.mocks']);

            characteristicsBuilder = $injector.get('policingCharacteristicsBuilderMock');
            caseValidCombinationService = $injector.get('caseValidCombinationServiceMock')

            $provide.value('policingCharacteristicsBuilder', characteristicsBuilder);
            $provide.value('caseValidCombinationService', caseValidCombinationService);
        });

        inject(function(policingCharacteristicsService) {
            service = policingCharacteristicsService;

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
            var validatorFunc = jasmine.createSpy().and.callFake(function(r, cb){
                return cb(r);
            });

            service.validate(formData, form, validatorFunc);
            expect(characteristicsBuilder.build).toHaveBeenCalledWith(formData);
            expect(validatorFunc).toHaveBeenCalledWith(characteristicsBuilder.build.returnValue, jasmine.any(Function));
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
        });
    });


    describe('Initialise controllers', function() {
        it('Initialises common controller data and methods', function() {
            var c = {};
            formData = {
                a: 'a'
            };
            service.initController(c, function() {}, formData);

            expect(c.formData).toBe(formData);
            expect(c.validate).toBeDefined();
            expect(c.extendPicklistQuery).toBe(caseValidCombinationService.extendValidCombinationPickList);
            expect(c.isDateOfLawDisabled).toBe(caseValidCombinationService.isDateOfLawDisabled);
            expect(c.isCaseCategoryDisabled).toBe(caseValidCombinationService.isCaseCategoryDisabled);
            expect(c.picklistValidCombination).toBe(caseValidCombinationService.validCombinationDescriptionsMap);
        });
    });
});
