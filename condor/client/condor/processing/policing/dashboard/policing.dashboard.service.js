angular.module('inprotech.processing.policing').service('policingDashboardService', function($http) {
    'use strict';

    return {
        permissions: function() {
            return $http.get('api/policing/dashboard/permissions');
        },
        dashboard: function() {
            return $http.get('api/policing/dashboard/view').then(function(response) {
                return response.data;
            });
        }
    };
});