angular.module('inprotech.processing.policing')
    .controller('PolicingRequestRunNowConfirmationController', function($scope, $uibModalInstance, request, policingRequestAffectedCasesService, canCalculateAffectedCases) {
        'use strict';

        var runTypes = {
            oneRequest: 1,
            separateCases: 2
        };

        var service = policingRequestAffectedCasesService;
        $scope.request = request;
        $scope.cancel = cancel;
        $scope.proceed = proceed;
        $scope.today = new Date();
        $scope.canCalculateAffectedCases = canCalculateAffectedCases;
        $scope.defaultDays = 'policing.request.runNow.varied';
        $scope.runMode = {
            type: runTypes.oneRequest
        };

        $scope.isStartDateInFuture = function() {
            if ($scope.request.startDate) {
                var start = new Date($scope.request.startDate);
                start.setHours(0);
                start.setMinutes(0);
                start.setSeconds(0);
                start.setMilliseconds(0);
                var today = new Date();
                return start > today;
            }
            return false;
        }

        $scope.isAffectedCasesAvailable = function() {
            return !(typeof($scope.request.noOfAffectedCases) === 'undefined' || $scope.request.noOfAffectedCases === null);
        }

        function cancel() {
            $uibModalInstance.close('Cancel');
        }

        function proceed() {
            $uibModalInstance.close({
                runType: $scope.runMode.type
            });
        }

        function calculateStartEndDate() {
            if (!$scope.request.startDate && !$scope.request.endDate && $scope.request.forDays) {
                $scope.request.startDate = new Date();
                $scope.request.endDate = new Date();
                if ($scope.request.forDays > 0) {
                    $scope.request.endDate.setDate(new Date().getDate() + ($scope.request.forDays - 1));
                } else {
                    $scope.request.startDate.setDate(new Date().getDate() + $scope.request.forDays);
                }
            }
        }

        function getAffectedCases() {
            if ($scope.canCalculateAffectedCases && !$scope.isAffectedCasesAvailable()) {
                service.getAffectedCases($scope.request.requestId).then(function(resp) {
                    $scope.$apply(function() {
                        $scope.request.noOfAffectedCases = resp.data.noOfCases;
                    });
                });
            }
        }

        getAffectedCases();
        calculateStartEndDate();
    });