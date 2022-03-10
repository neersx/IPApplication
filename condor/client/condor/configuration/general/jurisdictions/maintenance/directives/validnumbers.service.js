angular.module('inprotech.configuration.general.jurisdictions').factory('jurisdictionValidNumbersService', function($http) {
    'use strict';
    var baseUrl = 'api/configuration/jurisdictions/maintenance/';

    var service = {
        search: function(queryParams, id) {
            return $http.get(baseUrl + 'validNumbers/' + encodeURIComponent(id), {
                params: {
                    params: JSON.stringify(queryParams)
                }
            }).then(function(response) {
                return response.data;
            });
        },
        validateStoredProcedure: function(storedProcName) {
            return $http.get(baseUrl + 'validnumbers/validatestoredproc/' + encodeURIComponent(storedProcName)).then(function(response) {
                return response.data;
            });
        }
    };

    return service;
});

