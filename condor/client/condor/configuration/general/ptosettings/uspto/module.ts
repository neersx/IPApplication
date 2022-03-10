'use strict';

angular.module('inprotech.configuration.general.ptosettings.uspto', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components'
]);

angular.module('inprotech.configuration.general.ptosettings.uspto').config(function ($stateProvider) {
    $stateProvider.state('tsdrSettings', {
        url: '/pto-settings/uspto-tsdr',
        templateUrl: 'condor/configuration/general/ptosettings/uspto/tsdrsettings.html',
        controller: 'TsdrSettingsController',
        controllerAs: 'vm',
        resolve: {
            viewData: function ($http) {
                return $http.get('api/configuration/ptosettings/uspto-tsdr').then(function (response) {
                    return response.data.result;
                });
            }
        },
        data: {
            pageTitle: 'USPTO TSDR Integration Settings'
        }
    })
});
