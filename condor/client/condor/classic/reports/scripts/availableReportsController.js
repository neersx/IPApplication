angular.module('inprotech.financialReports')
    .controller('availableReportsController', [
        '$scope', '$http', 'viewInitialiser',
        function($scope, $http, viewInitialiser) {
            $scope.categorisedReports = [];
            $scope.categorisedReports = viewInitialiser.viewData;

            $scope.downloadLink = function(id) {
                return 'api/reports/report/' + id;
            }
        }
    ]);