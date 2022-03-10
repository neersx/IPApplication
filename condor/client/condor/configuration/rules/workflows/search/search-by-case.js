angular.module('inprotech.configuration.rules.workflows')
    .controller('ipSearchByCaseController', function ($scope, workflowsSearchService, workflowsCharacteristicsService) {
        'use strict';
        var vm = this;
        var charsService;
        vm.$onInit = onInit;

        function onInit() {
            charsService = workflowsCharacteristicsService;

            charsService.initController(vm, 'case', {
                applyTo: null,
                matchType: 'best-criteria-only'
            });

            vm.selectCase = selectCase;
            vm.handleActionSelected = handleActionSelected;
        }

        function selectCase() {
            var item = vm.formData.case;
            if (item && item.key) {
                workflowsSearchService.getCaseCharacteristics(item.key).then(function (caseChars) {
                    populateCharacteristics(caseChars);
                    handleActionSelected();
                });
            }
        }

        function populateCharacteristics(items) {
            resetCharacteristicFields();
            angular.extend(vm.formData, items);
        }

        function handleActionSelected() {
            var item = vm.formData.action;
            if (item && item.code && vm.formData.case) {
                workflowsSearchService.getDefaultDateOfLaw(vm.formData.case.key, item.code).then(function (result) {
                    vm.formData.dateOfLaw = {
                        key: result.key,
                        value: result.value
                    };
                });
            }
        }

        function resetCharacteristicFields() {
            _.each(charsService.characteristicFields, function (field) {
                if (field === 'action') {
                    return;
                }
                if (vm.form[field]) {
                    vm.form[field].$reset();
                }
            });
        }
    })
    .directive('ipSearchByCase', function () {
        'use strict';

        return {
            restrict: 'E',
            templateUrl: 'condor/configuration/rules/workflows/search/search-by-case.html',
            scope: {},
            controller: 'ipSearchByCaseController',
            controllerAs: 'vm',
            link: function (scope, element) {
                element.on('keydown', 'input', function (e) {
                    if (e.which === 9 && !e.shiftKey && $(e.target).attr('id') === 'case-picklist-input') {
                        $('#action-picklist-input').focus();

                        e.preventDefault();
                        return false;
                    }
                });

                scope.$on('$destroy', function () {
                    element.off('keydown');
                });
            }
        };
    });