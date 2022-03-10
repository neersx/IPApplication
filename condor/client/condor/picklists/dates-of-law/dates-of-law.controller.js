(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('datesOfLawController', function($scope) {
            var c = this;

            c.saveWithoutValidate = $scope.vm.saveWithoutValidate;
            $scope.vm.hasInlineGrid = true;
            $scope.vm.hasInlineGridError = angular.noop;
            $scope.vm.isInlineGridDirty = angular.noop;
        });
})();