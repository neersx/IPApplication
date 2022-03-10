angular.module('inprotech.configuration.rules.workflows')
    .component('ipWorkflowsEntrycontrolStepCategoryPicker', {
        bindings: {
            category: '=',
            stepType: '=',
            required: '=',
            name: '=',
            criteriaCharacteristics: '='
        },
        require: {
            form: '^form'
        },
        templateUrl: 'condor/configuration/rules/workflows/directives/entrycontrol-step-category-picker.html',
        controllerAs: 'vm',
        controller: function(workflowsEntryControlStepsService) {
            var vm = this;

            vm.isDirty = function() {
                return vm.form[vm.name].$dirty;
            }

            vm.translateCategory = function() {
                return workflowsEntryControlStepsService.translateStepCategory(vm.category.categoryName);
            }

            vm.extendTextTypeQuery = function(query) {
                return angular.extend({}, query, vm.category.query);
            }

            vm.getId = function(type) {
                if (vm.criteriaCharacteristics && vm.criteriaCharacteristics[type]) {
                    return vm.criteriaCharacteristics[type].key;
                }
                return '';
            }

            vm.getName = function(type) {
                if (vm.criteriaCharacteristics && vm.criteriaCharacteristics[type]) {
                    return vm.criteriaCharacteristics[type].value;
                }
                return '';
            }

            vm.designationStage = {
                externalScope: function() {
                    return {
                        jurisdiction: vm.getName('jurisdiction')
                    };
                },
                extendQuery: function(query) {
                    var extended = angular.extend({}, query, {
                        jurisdictionId: vm.getId('jurisdiction')
                    });

                    vm.designationStage.outgoingRequest = extended;
                    return extended;
                }
            };
        }
    });
