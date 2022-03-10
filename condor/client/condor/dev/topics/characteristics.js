angular.module('inprotech.dev').directive('ipDevTopicsCharacteristics', function() {
    'use strict';

    return {
        restrict: 'AE',
        templateUrl: 'condor/dev/topics/characteristics.html',
        scope: {},
        controller: 'ipDevTopicsCharacteristicsController',
        controllerAs: 'vm',
        bindToController: {
            topic: '=',
            form: '='
        }
    };
}).controller('ipDevTopicsCharacteristicsController', function() {
    'use strict';

    var vm = this;
    vm.errors = {};

    vm.topic.hasError = function() {
        return _.any(vm.errors, function(item) {
            return item.any();
        });
    };
});
