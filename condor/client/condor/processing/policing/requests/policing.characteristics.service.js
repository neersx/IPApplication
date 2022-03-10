angular.module('inprotech.processing.policing')
    .factory('policingCharacteristicsService', function(policingCharacteristicsBuilder, caseValidCombinationService) {
        'use strict';

        var characteristicFields = [
            'action',
            'caseCategory',
            'caseType',
            'dateOfLaw',
            'jurisdiction',
            'office',
            'propertyType',
            'subType'
        ];

        return {
            validate: validate,
            setValidation: setValidation,
            isCharacteristicField: isCharacteristicField,
            initController: initController,
            characteristicFields: characteristicFields
        };

        function validate(formData, form, validatorFunc) {
            var characteristics = policingCharacteristicsBuilder.build(formData);

            validatorFunc(characteristics, function(validationResults) {
                setValidation(validationResults, form);
            });
        }

        function setValidation(validationResults, form) {
            _.each(validationResults, function(pl, key) {
                if (!isCharacteristicField(key) || !form[key]) {
                    return;
                }

                if (pl.isValid) {
                    form[key].$setValidity('invalidcombination', null);
                    if (pl.value) {
                        form[key].$setText(pl.value);
                    }
                } else {
                    form[key].$setValidity('invalidcombination', false);
                }
            });
        }

        function isCharacteristicField(field) {
            return _.contains(characteristicFields, field);
        }

        function initController(vm, validatorFunc, formData) {
            vm.formData = formData;
            caseValidCombinationService.initFormData(vm.formData);

            vm.validate = function() {
                validate(vm.formData, vm.form, validatorFunc);
            };

            vm.applyValidation = function(validationResults) {
                setValidation(validationResults, vm.form);
            };

            vm.picklistValidCombination = caseValidCombinationService.validCombinationDescriptionsMap;
            vm.extendPicklistQuery = caseValidCombinationService.extendValidCombinationPickList;
            vm.isDateOfLawDisabled = caseValidCombinationService.isDateOfLawDisabled;        
            vm.isCaseCategoryDisabled = caseValidCombinationService.isCaseCategoryDisabled;
        }
    });
