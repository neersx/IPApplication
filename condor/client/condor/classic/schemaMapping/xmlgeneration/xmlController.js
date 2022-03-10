angular.module('Inprotech.SchemaMapping')
    .controller('xmlController', ['$scope', '$stateParams', '$http', '$location', '$timeout', '$window', 'url', 'viewInitialiser',
        function($scope, $stateParams, $http, $location, $timeout, $window, url, viewInitialiser) {
            'use strict';
            var getXml;

            $scope.id = $stateParams.id;
            $scope.mappingName = viewInitialiser.data.name;
            $scope.details = {
                entryPoint: null
            };

            $scope.status = 'idle';

            $scope.generateXml = function() {
                getXml('xmlview', function(result) {
                    $scope.xml = result;
                });
            };

            $scope.downloadXml = function() {
                getXml('xmldownload', function(response) {
                    $window.location = url.api('storage/' + response);
                });
            };

            $scope.errorContainsTempNameSpace = function() {
                var tempNamespace = 'http://tempuri.org/a';
                return ($scope.error && $scope.error.indexOf(tempNamespace) > -1);
            };

            getXml = function(method, onSuccess) {
                var apiUrl = url.api('schemamappings/' + $stateParams.id + '/' + method + '?gstrEntryPoint=' + $scope.details.entryPoint);

                $scope.status = 'generating';
                $scope.error = null;
                $scope.xml = null;

                $http
                    .get(apiUrl, {
                        handlesError: function(err) {
                            return err.status === 'FailedToGenerateXml';
                        }
                    })
                    .then(function(response) {
                        var result = response.data;
                        $scope.status = 'idle';
                        onSuccess(result.result || result);
                    }, function(response) {
                        var result = response.data;
                        $scope.status = 'idle';
                        $scope.xml = result.xml;
                        $scope.error = result.error;
                    });
            };
        }
    ]);