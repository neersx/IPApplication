(function() {
    'use strict';

    angular.module('inprotech.configuration.general.sitecontrols', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.sitecontrols').config(function($stateProvider) {
        $stateProvider.state('sitecontrols', {
            url: '/configuration/general/sitecontrols',
            templateUrl: 'condor/configuration/general/sitecontrols/sitecontrols.html',
            controller: 'SiteControlsController',
            controllerAs: 'vm',
            resolve: {
                viewData: function($http) {
                    return $http.get('api/configuration/sitecontrols/view').then(function(response) {
                        return response.data;
                    });
                }
            },
            data: {
                pageTitle: 'siteControls.summary'
            }
        });
    });
})();