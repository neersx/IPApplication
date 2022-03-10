angular.module('inprotech.processing.policing').service('policingServerService', function($http, policingDashboardService) {
    'use strict';

    return {
        canAdminister: function() {
            return policingDashboardService.permissions();
        },
        turnOff: function() {
            return $http.post('api/policing/dashboard/admin/turnOff');
        },
        turnOn: function() {
            return $http.post('api/policing/dashboard/admin/turnOn');
        }
    };
});
