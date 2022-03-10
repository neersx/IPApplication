angular.module('Inprotech.BulkCaseImport', ['Inprotech', 'inprotech.components'])
    .config(['$stateProvider', function($stateProvider) {
        $stateProvider
            .state('classicBulkCaseImport', {
                url: '/bulkcaseimport/import',
                templateUrl: 'condor/classic/bulkCaseImport/home.html',
                controller: 'homeController',
                resolve: {
                    viewInitialiser: function(http) {
                        return http.get('api/bulkCaseImport/homeView').success(function(data) {
                            return data;
                        });
                    }
                },
                data: {
                    pageTitle: 'bulkCaseImport.pageTitle'
                }
            })
            .state('classicBulkCaseImportStatus', {
                url: '/bulkcaseimport',
                templateUrl: 'condor/classic/bulkCaseImport/importStatus.html',
                controller: 'importStatusController',
                controllerAs: 'vm',
                resolve: {
                    permissions: function(http) {
                        return http.get('api/bulkCaseImport/permissions').success(function(data) {
                            return data;
                        });
                    }
                },
                data: {
                    pageTitle: 'bulkCaseImport.pageTitle'
                }
            })
            .state('classicBulkCaseIssuesName', {
                url: '/bulkcaseimport/issues/name/:batchId',
                templateUrl: 'condor/classic/bulkCaseImport/nameIssues.html',
                controller: 'nameIssuesController',
                resolve: {
                    viewInitialiser: function(http, $stateParams) {
                        return http.get('api/bulkCaseImport/nameIssuesView?batchId=' + $stateParams.batchId).success(function(data) {
                            return data;
                        });
                    }
                },
                data: {
                    pageTitle: 'bulkCaseImport.pageTitle'
                }
            })
            .state('classicBulkCaseIssuesMapping', {
                url: '/bulkcaseimport/issues/mapping/:batchId',
                templateUrl: 'condor/classic/bulkCaseImport/mappingIssues.html',
                controller: 'mappingIssuesController',
                resolve: {
                    viewInitialiser: function(http, $stateParams) {
                        return http.get('api/bulkCaseImport/mappingIssuesView?batchId=' + $stateParams.batchId).success(function(data) {
                            return data;
                        });
                    }
                },
                data: {
                    pageTitle: 'bulkCaseImport.pageTitle'
                }
            })
            .state('classicBulkCaseBatchSummary', {
                url: '/bulkcaseimport/batchSummary/:batchId',
                templateUrl: 'condor/classic/bulkCaseImport/batchSummary.html',
                controller: 'batchSummaryController',
                controllerAs: 'vm',
                resolve: {
                    batch: function(http, $stateParams) {
                        if ($stateParams.batchIdentifier) {
                            return {
                                id: $stateParams.batchId,
                                name: $stateParams.batchIdentifier,
                                transReturnCode: $stateParams.transReturnCode
                            }
                        }
                        return http.get('api/bulkCaseImport/batchsummary/batchidentifier?batchId=' + $stateParams.batchId).success(function(data) {
                            return data;
                        });
                    }
                },
                data: {
                    pageTitle: 'bulkCaseImport.pageTitle'
                }
            })
            .state('classicBulkCaseBatchSummaryReturnCode', {
                url: '/bulkcaseimport/batchSummary/:batchId/:transReturnCode',
                templateUrl: 'condor/classic/bulkCaseImport/batchSummary.html',
                controller: 'batchSummaryController',
                controllerAs: 'vm',
                resolve: {
                    batch: function(http, $stateParams) {
                        if ($stateParams.batchIdentifier) {
                            return {
                                id: $stateParams.batchId,
                                name: $stateParams.batchIdentifier,
                                transReturnCode: $stateParams.transReturnCode
                            }
                        }
                        return http.get('api/bulkCaseImport/batchsummary/batchidentifier?batchId=' + $stateParams.batchId + '&transReturnCode=' + $stateParams.transReturnCode).success(function(data) {
                            return data;
                        });
                    }
                },
                data: {
                    pageTitle: 'bulkCaseImport.pageTitle'
                }
            })
    }])    
    .run(function(modalService) {
        modalService.register('ImportStatusErrorPopup', 'ImportStatusErrorPopupController', 'condor/classic/bulkCaseImport/import-status-error-popup.html', {
            windowClass: 'centered picklist-window',
            backdrop: 'static',
            controllerAs: 'vm'
        });
    });