angular.module('inprotech.deve2e').controller('PicklistTestController', function($scope) {
    'use strict';

    var vm = this;
    vm.formResult = ''
    vm.setTableType = function(query) {
        var extended = angular.extend({}, query, {
            tableType: 'eventgroup'
        });
        return extended;
    };

    $scope.submitForm = function() {
        vm.formResult = 'pass';
    }
});