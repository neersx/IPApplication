angular.module('inprotech.processing.exchange').factory('exchangeSettingsService', function($http) {
    'use strict';
    var baseUrl = 'api/exchange/configuration/';

    var service = {
        get: function() {
            return $http.get(baseUrl + 'view')
                .then(function(response) {
                    return response.data;
                });
        },
        save: function(data) {
            return $http.post(baseUrl + 'save', data);
        },
        checkStatus: function(data) {
            return $http.get(baseUrl + 'status', data);
        }
    };

    return service;
});
