angular.module('Inprotech.BulkCaseImport')
    .controller('mappingIssuesController', ['$scope', 'viewInitialiser',
        function($scope, viewInitialiser) {
            'use strict';

            $scope.data = viewInitialiser.viewData;

            $scope.status = 'idle';
        }
    ]);
