angular.module('Inprotech.Integration.PtoAccess', ['Inprotech', 'inprotech.components'])
    .config(function($stateProvider) {

        $stateProvider
            .state('classicPtoAccess', {
                url: '/integration/ptoaccess',
                redirectTo: 'classicPtoAccess.Schedules'
            })
            .state('classicPtoAccess.Sponsorships', {
                url: '/uspto-private-pair-sponsorships',
                component: 'usptoPrivatePairSponsorshipsComponent',
                data: {
                    pageTitle: 'dataDownload.uspto.pageTitle'
                }
            })
            .state('classicPtoAccess.Sponsorships.New', {
                url: '/new-uspto-private-pair-sponsorships',
                templateUrl: 'condor/classic/integration/ptoaccess/uspto/privatepair/new-sponsorship.html'
            })
            .state('classicPtoAccess.Schedules', {
                url: '/schedules',
                controller: 'schedulesController',
                controllerAs: 'vm',
                templateUrl: 'condor/classic/integration/ptoaccess/schedules.html',
                data: {
                    pageTitle: 'dataDownload.pageTitle'
                }
            })
            .state('classicPtoAccess.SchedulesDetail', {
                url: '/schedule?:id',
                controller: 'scheduleController',
                controllerAs: 'vm',
                templateUrl: 'condor/classic/integration/ptoaccess/schedule.html',
                resolve: {
                    viewInitialiser: function($http, $stateParams, url) {
                        return $http.get(url.api('ptoaccess/scheduleView?id=' + $stateParams.id)).then(function(response) {
                            return response.data.result;
                        });
                    }
                },
                params: {
                    id: null
                },
                data: {
                    pageTitle: 'dataDownload.pageTitle'
                }
            })
            .state('classicPtoAccess.FailureSummary', {
                url: '/failure-summary',
                controller: 'failureSummaryController',
                controllerAs: 'vm',
                templateUrl: 'condor/classic/integration/ptoaccess/failure-summary.html',
                resolve: {
                    viewInitialiser: function($http, url) {
                        return $http.get(url.api('ptoaccess/failureSummaryView')).then(function(response) {
                            return response.data.result;
                        });
                    }
                },
                data: {
                    pageTitle: 'dataDownload.pageTitle'
                }
            });
    })
    .run(function(modalService) {

        modalService.register('RecoverableCases', 'recoverableCasesController', 'condor/classic/integration/ptoaccess/recoverable-dialog.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });
        modalService.register('RecoverableDocuments', 'recoverableDocumentsController', 'condor/classic/integration/ptoaccess/recoverable-documents-dialog.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'xl'
        });

        modalService.register('ErrorDetails', 'errorDetailsController', 'condor/classic/integration/ptoaccess/error-details-dialog.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });

        modalService.register('NewSchedule', 'newScheduleController', 'condor/classic/integration/ptoaccess/new-schedule.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });

        modalService.register('NewUsptoSponsorship', 'newUsptoPrivatePairSponsorshipController', 'condor/classic/integration/ptoaccess/uspto/privatepair/new-sponsorship.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });

        modalService.register('updateUsptoAccountDetails', 'updateUsptoAccountDetailsController', 'condor/classic/integration/ptoaccess/uspto/privatepair/update-account-details.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });
    });