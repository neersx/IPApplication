angular.module('inprotech.configuration.system.mui')
    .directive('ipEditableScreenLabel', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: {
                translation: '='
            },
            templateUrl: 'condor/configuration/system/mui/directives/editable-screen-item.html',
            controller: function($scope) {
                $scope.item = $scope.$parent.service.getOrAttach($scope.translation);
            }
        };
    });
