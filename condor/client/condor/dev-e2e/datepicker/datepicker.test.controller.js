angular.module('inprotech.deve2e').controller('DatepickerTestController', function (dateHelper) {
    'use strict';
    var vm = this;
    vm.$onInit = onInit;

    function onInit() {

        vm.onExistingDateChange = onExistingDateChange;

        // simulate populating data
        vm.existingDate = "2017-05-18T00:00:00";
        vm.existingDate = dateHelper.convertForDatePicker("2017-05-18T00:00:00");
    }

    function onExistingDateChange() {
        vm.repopulateDate = dateHelper.convertForDatePicker(vm.existingDate);
    }
});
