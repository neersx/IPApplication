angular.module('inprotech.dev').controller('DevFormController', function () {
    'use strict';
    var vm = this;
    vm.$onInit = onInit;

    function onInit() {
        vm.model1 = {
            text: 1,
            option: 'v1'
        };
        vm.model2 = {
            text: 2,
            option: 'v2'
        };
        vm.options = [{
            name: 'n1',
            value: 'v1'
        }, {
            name: 'n2',
            value: 'v2'
        }];
        vm.checkbox2 = true;
        vm.isDisabled = true;
        vm.radio1 = true;
        vm.errorMessage = 'field.errors.required';
        vm.isDisabled2 = true;
        vm.dd = {
            model1: 'v1',
            disabled: true
        };
    }
    vm.isTextDisabled = function (option) {
        return option === 'v1';
    };
    vm.getWarningText = function () {
        return "This is warning";
    }
});
