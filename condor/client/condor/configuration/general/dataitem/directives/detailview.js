angular.module('inprotech.configuration.general.dataitem').directive('iptDataitemDetailView', function() {
    'use strict';

    return {
        restrict: 'E',
        scope: {
            parent: '='
        },
        templateUrl: 'condor/configuration/general/dataitem/directives/detailview.html',
        controller: function($scope) {
            $scope.item = $scope.parent;
        }
    };
});