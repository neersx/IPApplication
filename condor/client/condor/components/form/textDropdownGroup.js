angular.module('inprotech.components.form').component('ipTextDropdownGroup', {
    templateUrl: 'condor/components/form/textDropdownGroup.html',
    bindings: {
        label: '@',
        textField: '@',
        optionField: '@',
        options: '@',
        isTextDisabled: '<',
        warningText: '&'
    },
    require: {
        'ngModel': '?ngModel',
        'formCtrl': '?^ipForm'
    },
    controllerAs: 'vm',
    controller: function($element, $attrs, formControlHelper) {
        'use strict';

        var vm = this;
        vm.$onInit = onInit;

        function onInit() {

            vm.textField = vm.textField || 'text';
            vm.optionField = vm.optionField || 'option';

            formControlHelper.init({
                scope: vm,
                className: 'text-dropdown-group',
                element: $element,
                attrs: $attrs,
                ngModelCtrl: vm.ngModel,
                formCtrl: vm.formCtrl,
                onRender: function(value) {
                    if (value == null) {
                        vm.text = null;
                        vm.option = null;
                    } else {
                        vm.text = value[vm.textField];
                        vm.option = value[vm.optionField];
                        setTextField(vm.option);
                    }
                },
                onChange: function() {
                    setTextField(vm.option);
                    if (vm.textDisabled && !vm.option) {
                        vm.model = null;
                    } else if (!vm.textDisabled && (!vm.text || !vm.option)) {
                        vm.model = null;
                    } else {
                        vm.model = {};
                        vm.model[vm.textField] = vm.text;
                        vm.model[vm.optionField] = vm.option;
                    }
                }
            });

            vm.transform = formControlHelper.transcludeNgOptions;
        }

        function setTextField() {
            if (!vm.isTextDisabled) {
                return;
            }

            var isDisabled = vm.isTextDisabled.apply(this, arguments);
            vm.textDisabled = isDisabled;

            if (isDisabled) {
                vm.text = '';
            }
        }
    }
});
