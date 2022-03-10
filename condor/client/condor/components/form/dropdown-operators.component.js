angular.module('inprotech.components.form').component('ipDropdownOperators', {
    templateUrl: 'condor/components/form/dropdown-operators.html',
    bindings: {
        label: '@',
        operatorsGroup: '@?',
        customOperators: '@?'
    },
    require: {
        'ngModel': '?ngModel',
        'formCtrl': '?^ipForm'
    },
    controllerAs: 'vm',
    controller: function($element, $attrs, formControlHelper, $scope, $filter) {
        'use strict';

        var vm = this;

        var $translate = $filter('translate');
        var options = {
            equalTo: { key: '0', value: $translate("operators.equalTo") },
            notEqualTo: { key: '1', value: $translate("operators.notEqualTo") },
            startsWith: { key: '2', value: $translate("operators.startsWith") },
            endsWith: { key: '3', value: $translate("operators.endsWith") },
            contains: { key: '4', value: $translate("operators.contains") },
            exists: { key: '5', value: $translate("operators.exists") },
            notExists: { key: '6', value: $translate("operators.notExists") },
            between: { key: '7', value: $translate("operators.between") },
            notBetween: { key: '8', value: $translate("operators.notBetween") },
            soundsLike: { key: '9', value: $translate("operators.soundsLike") },
            lessThan: { key: '10', value: $translate("operators.lessThan") },
            lessEqual: { key: '11', value: $translate("operators.lessEqual") },
            greater: { key: '12', value: $translate("operators.greater") },
            greaterEqual: { key: '13', value: $translate("operators.greaterEqual") }
        }

        var dateOptions = {
            withinLast: { key: 'L', value: $translate("operators.withinLast") },
            withinNext: { key: 'N', value: $translate("operators.withinNext") },
            specificDate: { key: 'sd', value: $translate("operators.SpecificDates") }
        }

        var optionsCombinations = {
            "Full": [options.equalTo, options.notEqualTo, options.startsWith, options.endsWith, options.contains, options.exists, options.notExists],
            "FullSoundsLike": [options.equalTo, options.notEqualTo, options.startsWith, options.endsWith, options.contains, options.exists, options.notExists, options.soundsLike],
            "FullNoExist": [options.equalTo, options.notEqualTo, options.startsWith, options.endsWith, options.contains],
            "Equal": [options.equalTo, options.notEqualTo],
            "Between": [options.between, options.notBetween],
            "EqualExist": [options.equalTo, options.notEqualTo, options.exists, options.notExists],
            "DatesFull": [options.equalTo, options.notEqualTo, options.lessThan, options.lessEqual, options.greater, options.greaterEqual, options.exists, options.notExists, dateOptions.withinLast, dateOptions.withinNext, dateOptions.specificDate]
        };
        vm.id = $scope.$id;
        vm.$onInit = onInit;

        function onInit() {
            vm.options = [];
            if (vm.operatorsGroup)
                vm.options = optionsCombinations[vm.operatorsGroup] || optionsCombinations['Equal'];
            if (vm.customOperators) {
                var operatorsArray = vm.customOperators.split(',');
                _.forEach(operatorsArray, function(o) {
                    if (options[o]) {
                        vm.options.push(options[o]);
                    }
                });
            }
            formControlHelper.init({
                scope: vm,
                className: 'ip-dropdown',
                inputSelector: 'select',
                element: $element,
                attrs: $attrs,
                ngModelCtrl: vm.ngModel,
                formCtrl: vm.formCtrl
            });
        }
    }
});