angular.module('inprotech.configuration.rules.workflows').factory('workflowsCharacteristicsService',
    function($q, characteristicsBuilder, characteristicsValidator, sharedService, workflowsSearchService, selectedCaseType, caseValidCombinationService) {
        'use strict';

        var characteristicFields = [
            'action',
            'basis',
            'caseCategory',
            'caseType',
            'dateOfLaw',
            'jurisdiction',
            'office',
            'propertyType',
            'subType',
            'examinationType',
            'renewalType'
        ];

        return {
            validate: validate,
            setValidation: setValidation,
            characteristicFields: characteristicFields,
            isCharacteristicField: isCharacteristicField,
            initController: initController,
            showExaminationType: showExaminationType,
            showRenewalType: showRenewalType
        };

        function validate(formData, form) {
            var criteria = characteristicsBuilder.build(formData);

            characteristicsValidator.validate(criteria, function(validationResults) {
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
                    form[key].$setValidity('invalidcombination', form[key].$$attr.disabled ? null : false); 
                }
            });
        }

        function isCharacteristicField(field) {
            return _.contains(characteristicFields, field);
        }

        function initController(vm, name, formData) {
            vm.formData = formData;

            vm.formData.includeProtectedCriteria = sharedService.includeProtectedCriteria;

            vm.validate = function() {
                selectedCaseType.set(vm.formData.caseType);
                validate(vm.formData, vm.form);
            };

            vm.vcService = caseValidCombinationService;
            vm.vcService.initFormData(vm.formData);
            vm.picklistValidCombination = vm.vcService.validCombinationDescriptionsMap;
            vm.extendPicklistQuery = vm.vcService.extendValidCombinationPickList;
            vm.isDateOfLawDisabled = vm.vcService.isDateOfLawDisabled;
            vm.isCaseCategoryDisabled = vm.vcService.isCaseCategoryDisabled;

            vm.appliesToOptions = [{
                value: 'local-clients',
                label: 'workflows.common.localOrForeignDropdown.localClients'
            }, {
                value: 'foreign-clients',
                label: 'workflows.common.localOrForeignDropdown.foreignClients'
            }];

            vm.hasOffices = sharedService.hasOffices;

            vm.showExaminationType = function() {
                return showExaminationType(vm.formData);
            };

            vm.showRenewalType = function() {
                return showRenewalType(vm.formData);
            };

            sharedService[name] = {
                defaultFormData: angular.copy(formData),
                onEnter: function() {
                    vm.vcService.initFormData(vm.formData)
                },
                validate: function() {
                    vm.form.$validate();
                },
                search: function(queryParams) {
                    vm.form.$validate();
                    if (vm.form.$invalid) {
                        return $q.reject();
                    }

                    if (name === 'criteria') {
                        return workflowsSearchService.searchByIds(vm.formData, queryParams);
                    }

                    return workflowsSearchService.search(vm.formData, queryParams);
                },
                reset: function() {
                    vm.formData = angular.copy(this.defaultFormData);
                    vm.vcService.initFormData(vm.formData);
                },
                isSearchDisabled: function() {
                    return vm.form.$loading || vm.form.$invalid;
                },
                characteristicsSelected: function() {
                    var localClient = {
                        isLocalClient: vm.formData.applyTo ? vm.formData.applyTo === 'local-clients' : null
                    }
                    return _.extend(localClient, _.pick(vm.formData, function(v, k) {
                        return isCharacteristicField(k) && (vm.form[k] ? vm.form[k].$valid : false);
                    }));
                },
                selectedMatchType: function() {
                    return vm.formData.matchType;
                }
            };
        }

        function showExaminationType(formData) {
            if (formData.action && formData.action.actionType === 'examination') {
                return true;
            }
            formData.examinationType = null;
            return false;
        }

        function showRenewalType(formData) {
            if (formData.action && formData.action.actionType === 'renewal') {
                return true;
            }
            formData.renewalType = null;
            return false;
        }
    });