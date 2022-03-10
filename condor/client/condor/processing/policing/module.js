(function() {
    'use strict';

    angular.module('inprotech.processing.policing', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.processing.policing').config(function($stateProvider) {
        $stateProvider
            .state('policingDashboard', {
                url: '/policing-dashboard?{rinterval:int}',
                templateUrl: 'condor/processing/policing/dashboard/dashboard.html',
                controller: 'PolicingDashboardController',
                controllerAs: 'vm',
                resolve: {
                    refreshInterval: ['$stateParams', function($stateParams) {
                        if ($stateParams.rinterval) {
                            return $stateParams.rinterval;
                        }
                        return 30;
                    }]
                },
                data: {
                    pageTitle: 'Policing'
                }
            })
            .state('policingQueue', {
                url: '/policing-queue/:queueType?{rinterval:int}',
                templateUrl: 'condor/processing/policing/queue/queue.html',
                controller: 'PolicingQueueController',
                controllerAs: 'vm',
                resolve: {
                    queueType: ['$stateParams', function($stateParams) {
                        return $stateParams.queueType;
                    }],
                    refreshInterval: ['$stateParams', function($stateParams) {
                        if ($stateParams.rinterval) {
                            return $stateParams.rinterval;
                        }
                        return 30;
                    }],
                    viewData: function($http) {
                        return $http.get('api/policing/queue/view').then(function(response) {
                            return response.data;
                        });
                    }
                },
                data: {
                    pageTitle: 'Policing'
                }
            })
            .state('policingRequestLog', {
                url: '/policing-request-log?{policingLogId:int}',
                templateUrl: 'condor/processing/policing/requestsLog/request.log.html',
                controller: 'PolicingRequestLogController',
                controllerAs: 'vm',
                data: {
                    pageTitle: 'Policing'
                },
                resolve: {
                    viewData: function($http) {
                        return $http.get('api/policing/requestlog/view').then(function(response) {
                            return response.data;
                        });
                    },
                    policingLogId: ['$stateParams', function($stateParams) {
                        return $stateParams.policingLogId;
                    }]
                }
            })
            .state('policingErrorLog', {
                url: '/policing-error-log',
                templateUrl: 'condor/processing/policing/errorLog/error.log.html',
                controller: 'PolicingErrorLogController',
                controllerAs: 'vm',
                data: {
                    pageTitle: 'Policing'
                },
                resolve: {
                    viewData: function($http) {
                        return $http.get('api/policing/errorLog/view').then(function(response) {
                            return response.data;
                        });
                    }
                }
            })
            .state('policingRequestMaintenance', {
                url: '/policing-saved-requests',
                templateUrl: 'condor/processing/policing/requests/saved.requests.html',
                controller: 'ipPolicingSavedRequestsController',
                controllerAs: 'vm',
                data: {
                    pageTitle: 'Policing Requests'
                },
                resolve: {
                    viewData: function($http) {
                        return $http.get('api/policing/requests/view').then(function(response) {
                            return response.data;
                        });
                    }
                }
            });
    });

    angular.module('inprotech.processing.policing')
        .run(function(modalService) {
            modalService.register('PolicingQueueErrors', 'ipQueueErrordetailviewController', 'condor/processing/policing/queue/directives/errorView/queue.errordetailview.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        })
        .run(function(modalService) {
            modalService.register('NextRunTime', 'PolicingNextRunTimeController', 'condor/processing/policing/queue/directives/nextruntime/nextruntime.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        })
        .run(function(modalService) {
            modalService.register('PolicingRequestLogErrors', 'ipPolicingRequestLogerrordetailController', 'condor/processing/policing/requestsLog/directives/policing.request.logerrordetail.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        })
        .run(function(modalService) {
            modalService.register('PolicingRequestMaintain', 'PolicingRequestMaintenanceController', 'condor/processing/policing/requests/policing.requests.maintenance.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg',
                controllerAs: 'vm'
            });
        })
        .run(function(modalService) {
            modalService.register('PolicingRequestRunNowConfirmation', 'PolicingRequestRunNowConfirmationController', 'condor/processing/policing/requests/policing.requests.runnow.confirmation.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'md',
                controllerAs: 'vm'
            });

            modalService.register('PolicingRequestAffectedCases', 'PolicingRequestAffectedCasesController', 'condor/processing/policing/requests/policing.request.affectedcases.html', {
                windowClass: 'centered',
                backdropClass: 'centered',
                size: 'sm',
                controllerAs: 'vm'
            });
        });
})();