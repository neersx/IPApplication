angular.module('inprotech.dashboard').controller('DashboardController', function (appContext, $window) {
    'use strict';

    var vm = this;
    vm.$onInit = onInit;

    function onInit() {
        vm.username = appContext.user.name;
        vm.debug = $window.INPRO_DEBUG;
        vm.e2e = $window.INPRO_INCLUDE_E2E_PAGES;
    }
});

