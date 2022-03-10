(function() {
    'use strict';

    angular.module('inprotech.configuration.general.jurisdictions', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.jurisdictions')
        .run(function(modalService) {
            modalService.register('CreateJurisdiction', 'CreateJurisdictionController', 'condor/configuration/general/jurisdictions/maintenance/create.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });

            modalService.register('GroupMembershipMaintenance', 'GroupMembershipMaintenanceController', 'condor/configuration/general/jurisdictions/maintenance/directives/groups.maintenance.html', {
                windowClass: 'centered picklist-window',
                size: 'lg',
                bindToController: true,
                controllerAs: 'vm'
            });

            modalService.register('ValidNumbersMaintenance', 'ValidNumbersMaintenanceController', 'condor/configuration/general/jurisdictions/maintenance/directives/validnumbers.maintenance.html', {
                windowClass: 'centered picklist-window',
                size: 'lg',
                bindToController: true,
                controllerAs: 'vm'
            });

            modalService.register('BusinessdaysMaintenance', 'BusinessdaysMaintenanceController', 'condor/configuration/general/jurisdictions/maintenance/directives/businessdays.maintenance.html', {
                windowClass: 'centered picklist-window',
                size: 'lg',
                bindToController: true,
                controllerAs: 'vm'
            });


            modalService.register('ValidnumbersTestpattern', 'ValidNumbersTestPatternController', 'condor/configuration/general/jurisdictions/maintenance/directives/validnumbers.testpattern.html', {
                windowClass: 'centered picklist-window',
                size: 'lg',
                bindToController: true,
                controllerAs: 'vm'
            });

            modalService.register('ClassesMaintenance', 'ClassesMaintenanceController', 'condor/configuration/general/jurisdictions/maintenance/directives/classes.maintenance.html', {
                windowClass: 'centered picklist-window',
                size: 'lg',
                bindToController: true,
                controllerAs: 'vm'
            });

            modalService.register('ChangeJurisdictionCode', 'ChangeJurisdictionCodeController', 'condor/configuration/general/jurisdictions/search/jurisdiction.changecode.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        })
        .config(function($stateProvider) {
            $stateProvider.state('jurisdictions', {
                url: '/configuration/general/jurisdictions',
                templateUrl: 'condor/configuration/general/jurisdictions/search/index.html',
                controller: 'JurisdictionsController',
                controllerAs: 'vm',
                data: {
                    pageTitle: 'Jurisdictions'
                },
                resolve: {
                    initialData: function(jurisdictionsService) {
                        return jurisdictionsService.initialData();
                    }
                }
            }).state('jurisdictions.detail', {
                url: '/maintenance/{id}',
                templateUrl: 'condor/configuration/general/jurisdictions/maintenance/index.html',
                controller: 'JurisdictionMaintenanceController',
                controllerAs: 'vm',
                resolve: {
                    viewData: function($http, $stateParams) {
                        return $http.get('api/configuration/jurisdictions/maintenance/' + encodeURIComponent($stateParams.id)).then(function(response) {
                            return response.data;
                        });
                    },
                    appContext: 'appContext'
                },
                data: {}
            }).state('jurisdictions.default', {
                url: '/maintenance/:id/:navigatedSource',
                params: {
                    id: 'ZZZ',
                    navigatedSource: 'classes'
                },
                templateUrl: 'condor/configuration/general/jurisdictions/maintenance/index.html',
                controller: 'JurisdictionMaintenanceController',
                controllerAs: 'vm',
                resolve: {
                    viewData: function($http, $stateParams) {
                        return $http.get('api/configuration/jurisdictions/maintenance/' + encodeURIComponent($stateParams.id)).then(function(response) {
                            return response.data;
                        });
                    },
                    appContext: 'appContext'
                },
                data: {}
            });
        });
})();