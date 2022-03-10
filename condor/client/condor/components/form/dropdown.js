angular.module('inprotech.components.form').component('ipDropdown', {
    templateUrl: 'condor/components/form/dropdown.html',
    bindings: {
        label: '@',
        labelValue: '@?',
        options: '@',
        warningText: '&',
        optionalValue: '@?',
        errorText: '&?'
    },
    require: {
        'ngModel': '?ngModel',
        'formCtrl': '?^ipForm'
    },
    controllerAs: 'vm',
    controller: function ($element, $attrs, formControlHelper, $scope) {
        'use strict';

        var vm = this;

        vm.$onInit = onInit;

        function onInit() {
            vm.optional = $attrs['required'] == null;
            vm.id = $scope.$id;

            formControlHelper.init({
                scope: vm,
                className: 'ip-dropdown',
                inputSelector: 'select',
                element: $element,
                attrs: $attrs,
                ngModelCtrl: vm.ngModel,
                formCtrl: vm.formCtrl
            });

            vm.transform = formControlHelper.transcludeNgOptions;
        }
    }
});
