angular.module('inprotech.components.form').component('ipCheckbox', {
    template: '<div class="input-wrap"><input type="checkbox"><label translate="{{vm.label}}" translate-values="{{vm.labelValues}}"></label>' +
        '<ip-inline-dialog ng-if="::vm.info" data-content="{{:: vm.info | translate:vm.infoData }}"></ip-inline-dialog></div>',
    bindings: {
        label: '@',
        labelValues: '@?',
        info: '@',
        infoData: '<?',
        focusWhen: '<?'
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
        vm.$onChanges = onChanges;

        function onInit() {
            if (vm.ngModel) {
                vm.ngModel.$render = function() {
                    var checked = vm.ngModel.$viewValue;
                    $element.find('input:checkbox').prop('checked', checked);
                };
            }

            $element.find('input:checkbox').on('change', function() {
                var checked = $(this).prop('checked');
                if (vm.ngModel) {
                    vm.ngModel.$setViewValue(checked);
                }
            });

            $element.find('label').on('click', function(e) {
                $element.find('input:checkbox').click();
                e.stopPropagation();
            });

            $attrs.$observe('disabled', function(val) {
                if (_.isString(val)) {
                    val = val !== 'false';
                }

                if (val) {
                    $element.find('input:checkbox').attr('disabled', 'disabled');
                } else {
                    $element.find('input:checkbox').removeAttr('disabled');
                }
            });

            if ($attrs.hasOwnProperty('disabled')) {
                $element.find('input:checkbox').attr('disabled', 'disabled');
            }
        }

        function onChanges(changes) {
            if (changes.focusWhen && changes.focusWhen.currentValue) {
                $element.find('input:checkbox').focus();
            }
        }

        function onDestroy() {
            $element.find('label').off();
            $element.find('input:radio').off();
        }
    }
});