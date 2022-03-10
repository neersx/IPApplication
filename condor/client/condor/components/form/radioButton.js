angular.module('inprotech.components.form').component('ipRadioButton', {
    template: '<div class="input-wrap"><input type="radio"><label><span translate="{{::vm.label}}"></span></label></div>',
    bindings: {
        label: '@'
    },
    require: {
        'ngModel': '?ngModel'
    },
    controllerAs: 'vm',
    controller: function($element, $attrs) {
        'use strict';

        var vm = this;

        vm.$onDestroy = onDestroy;
        vm.$onInit = onInit;

        function onInit() {
            if (vm.ngModel) {
                vm.ngModel.$render = function() {
                    var checked = $attrs.value === vm.ngModel.$viewValue;
                    $element.find('input:radio').prop('checked', checked);
                };
            }

            $element.find('input:radio').on('change', function() {
                var checked = $(this).prop('checked');
                if (checked && vm.ngModel) {
                    vm.ngModel.$setViewValue($attrs.value);
                }
            });

            $element.find('label').on('click', function(e) {
                $element.find('input:radio').click();
                e.stopPropagation();
            });

            $attrs.$observe('disabled', function(val) {
                if (val === 'false' || val === false) {
                    $element.find('input:radio').removeAttr('disabled');
                } else {
                    $element.find('input:radio').attr('disabled', 'disabled');
                }
            });
        }

        function onDestroy() {
            $element.find('label').off();
            $element.find('input:radio').off();
        }
    }
});
