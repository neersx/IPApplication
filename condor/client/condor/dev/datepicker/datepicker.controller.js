angular.module('inprotech.dev').controller('DatePickerController', function () {
    'use strict';

    var vm = this;
    var now = new Date();
    vm.$onInit = onInit;

    function onInit() {
        vm.empty = model();
        vm.initialised = model(now);
        vm.required = model();
        vm.disabled = makeDisabled(model());
        vm.readonly = makeReadOnly(model());
        vm.external = model(now);
        vm.reset = model(now);
        vm.saved = model(now);
        vm.modified = model(now);
    }

    function model(date) {
        return {
            date: date || null,
            isDisabled: false,
            isReadOnly: false
        };
    }

    function makeReadOnly(o) {
        o.isReadOnly = true;
        return o;
    }

    function makeDisabled(o) {
        o.isDisabled = true;
        return o;
    }
});

