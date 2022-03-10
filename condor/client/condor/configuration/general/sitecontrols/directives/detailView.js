angular.module('inprotech.configuration.general.sitecontrols').directive('iptSitecontrolDetailView', function() {
    'use strict';

    return {
        restrict: 'E',
        scope: {
            parent: '=',
            canUpdate: '='
        },
        templateUrl: 'condor/configuration/general/sitecontrols/directives/detailView.html',
        controller: function($scope) {
            $scope.$parent.service.get($scope.parent.id).then(function(data) {
                $scope.item = data;
                $scope.inputType = data.dataType === 'Integer' || data.dataType === 'Decimal' ? 'number' : 'text';
            });
        }
    };
});
