angular.module('inprotech.dev').controller('DevDetailPageNavController', function ($q, $stateParams, LastSearch) {
    'use strict';

    var vm = this;
    vm.$onInit = onInit;

    function onInit() {
        vm.lastSearch = new LastSearch({
            method: function () {
                return $q.when([1, 2, 3, 4, 5]);
            },
            args: []
        });

        vm.id = $stateParams.id;
    }
});
