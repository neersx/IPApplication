angular.module('Inprotech.BulkCaseImport')
    .controller('resubmitController', ['$scope', 'http', 'notificationService', 'url', '$translate',
        function ($scope, http, notificationService, url, $translate) {
            'use strict';

            $scope.resubmitStatus = 'idle';

            var onComplete = function (response) {
                if (response.result === 'success') {
                    notificationService.success($translate.instant('bulkCaseImport.niResubmitSuccessMessage', {
                        identifier: $scope.viewData.batchIdentifier
                    }));
                    $scope.resubmitStatus = 'success';
                    return;

                }
                if (response.result === 'error') {
                    notificationService.alert({
                        message: response.errorMessage
                    })
                    $scope.resubmitStatus = 'idle';
                    return;
                }
            };

            $scope.resubmitBatch = function () {
                http.post(url.api('bulkcaseimport/resubmitbatch'), {
                    'batchId': $scope.viewData.batchId
                })
                    .success(function (response) {
                        onComplete(response);
                    });
            };
        }
    ]);