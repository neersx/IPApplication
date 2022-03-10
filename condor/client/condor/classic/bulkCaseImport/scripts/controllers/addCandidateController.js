angular.module('Inprotech.BulkCaseImport')
    .controller('addCandidateController', [
        '$scope', 'http', 'url',
        function($scope, http, url) {
            'use strict';

            $scope.status = 'idle';
            $scope.nameSelected = null;

            $scope.nameSourceList = function(e) {
                return http.get(
                    url.api('lists/names?type=all&' + url.query({
                        q: encodeURIComponent(e)
                    })));
            };
            var addOrSelect = function(nameSelected) {

                if ($scope.selectCandidateById(parseInt(nameSelected.key))) {
                    return;
                }

                $scope.status = 'busy';

                http.get(
                        url.api('bulkcaseimport/unresolvedname/candidates?' + url.query({
                            id: $scope.selectedUnresolved.id,
                            candidateId: nameSelected.key
                        })))
                    .success(function(response) {
                        $scope.selectedUnresolved.mapCandidates.splice(0, 0, response.mapCandidates[0]);
                        $scope.onCandidateSelected($scope.selectedUnresolved.mapCandidates[0]);
                        $scope.selectedAutomatically = true;
                        $scope.status = 'idle';
                    })
                    .catch(function() {
                        $scope.status = 'idle';
                    });
            };

            $scope.$watch('nameSelected', function(nameSelected) {
                if (nameSelected) {
                    addOrSelect(nameSelected);
                    $scope.nameSelected = null;
                }
            });
        }
    ]);
