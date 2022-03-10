'use strict';

angular.module('inprotech.configuration.general.ptosettings.epo', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components'
]);

angular.module('inprotech.configuration.general.ptosettings.epo').config(function ($stateProvider) {
    $stateProvider.state('epoSettings', {
        url: '/pto-settings/epo',
        templateUrl: 'condor/configuration/general/ptosettings/epo/eposettings.html',
        controller: 'EpoSettingsController',
        controllerAs: 'vm',
        resolve: {
            viewData: function ($http) {
                return $http.get('api/configuration/ptosettings/epo').then(function (response) {
                    return response.data.result;
                });
            }
        },
        data: {
            pageTitle: 'EPO Integration Settings'
        }
    })
});
