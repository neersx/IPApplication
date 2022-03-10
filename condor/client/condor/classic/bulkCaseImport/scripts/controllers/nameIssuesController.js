angular.module('Inprotech.BulkCaseImport')
    .controller('nameIssuesController', ['$scope', 'http', 'url', 'viewInitialiser',
        function($scope, http, url, viewInitialiser) {
            'use strict';

            $scope.viewData = viewInitialiser.viewData;
            $scope.status = 'idle';

            var next = function(items, current) {
                if (items && items.length > 0) {
                    var max = items.length - 1;
                    var index = _.indexOf(items, current);
                    var nextIndex = index + 1 > max ? max : index + 1;
                    return items[nextIndex];
                }
                return current;
            };

            var previous = function(items, current) {
                if (items && items.length > 0) {
                    var index = _.indexOf(items, current);
                    var prev = index - 1 < 0 ? 0 : index - 1;
                    return items[prev];
                }
                return current;
            };

            var selectFirstCandidate = function() {
                if (!$scope.selectedUnresolved || !$scope.selectedUnresolved.mapCandidates) {
                    return;
                }

                if ($scope.selectedUnresolved.mapCandidates.length > 0) {
                    $scope.onCandidateSelected($scope.selectedUnresolved.mapCandidates[0]);
                }
            };

            $scope.hasNameIssues = function() {
                return $scope.viewData.nameIssues.length > 0;
            };

            $scope.onUnresolvedNameSelected = function(n) {
                if (n !== $scope.selectedUnresolved) {
                    $scope.selectedCandidate = null;
                }

                $scope.selectedUnresolved = n;

                if ($scope.selectedUnresolved.mapCandidates) {
                    selectFirstCandidate();
                    return;
                }

                $scope.status = 'busy';

                http.get(
                        url.api('bulkcaseimport/unresolvedname/candidates?' + url.query({
                            id: n.id
                        })))
                    .success(function(response) {
                        $scope.selectedUnresolved.mapCandidates = response.mapCandidates || [];
                        selectFirstCandidate();
                        $scope.status = 'idle';
                    })
                    .catch(function() {
                        $scope.status = 'idle';
                    });
            };

            $scope.onCandidateSelected = function(n) {
                $scope.selectedCandidate = n;
                $scope.selectedAutomatically = false;
            };

            $scope.selectCandidateById = function(id) {
                var matched = _.find($scope.selectedUnresolved.mapCandidates, function(candidate) {
                    return candidate.id === id;
                });

                if (matched) {
                    $scope.selectedCandidate = matched;
                    $scope.selectedAutomatically = true;
                    return true;
                }

                return false;
            };

            $scope.mapName = function() {

                if (!$scope.selectedCandidate) {
                    return;
                }

                $scope.status = 'mapping';

                http.post(
                        url.api('bulkcaseimport/unresolvedname/mapname'), {
                            batchId: $scope.viewData.batchId,
                            unresolvedNameId: $scope.selectedUnresolved.id,
                            mapNameId: $scope.selectedCandidate.id
                        })
                    .success(function() {
                        var index = $scope.viewData.nameIssues.indexOf($scope.selectedUnresolved);
                        var n = (index === $scope.viewData.nameIssues.length - 1) ?
                            previous($scope.viewData.nameIssues, $scope.selectedUnresolved) :
                            next($scope.viewData.nameIssues, $scope.selectedUnresolved);

                        if (index > -1) {
                            $scope.viewData.nameIssues.splice(index, 1);
                        }

                        if ($scope.viewData.nameIssues.length > 0) {
                            $scope.onUnresolvedNameSelected(n);
                            $scope.status = 'idle';
                        } else {
                            $scope.status = 'complete';
                        }
                    })
                    .catch(function() {
                        $scope.status = 'idle';
                    });
            };

            if ($scope.hasNameIssues()) {
                $scope.selectedUnresolved = viewInitialiser.viewData.nameIssues[0];
                selectFirstCandidate();
            }
        }
    ]);
