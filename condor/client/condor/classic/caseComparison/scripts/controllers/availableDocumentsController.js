angular.module('Inprotech.CaseDataComparison')
    .controller('availableDocumentsController', [
        '$scope', 'comparisonDataSourceMap', 'modalService', 'notificationService',
        function($scope, comparisonDataSourceMap, modalService, notificationService) {
            'use strict';

            $scope.documentToImport = null;

            $scope.importDocument = function(ud) {
                $scope.documentToImport = {
                    caseId: $scope.caseId,
                    document: ud
                };

                openMaintenanceDialog({
                    caseId: $scope.caseId,
                    document: ud
                });
            };

            var openMaintenanceDialog = function(request) {
                modalService.open('ImportDocument', $scope, {
                    documentToImport: function() {
                        return request;
                    }
                }).then(function(result) {
                    if (result === 'success') {
                        $scope.documentToImport.document.imported = true;
                        $scope.documentToImport = null;
                        notificationService.success('caseComparisonInbox.lblSuccessfulAttachment');
                    }
                });
            };

            $scope.$watch('dataSource', function() {
                $scope.docTemplate = $scope.dataSource ? comparisonDataSourceMap.template($scope.dataSource) : null;
            });
        }
    ]);