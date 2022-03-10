angular.module('inprotech.processing.exchange').factory('exchangeQueueService', function($http) {
    'use strict';
    var baseUrl = 'api/exchange/requests/';

    var service = {
        reset: function(ids) {
            return $http.post(baseUrl + 'reset', ids);
        },
        get: function(queryParams) {
            return $http.post(baseUrl + 'view', JSON.stringify(queryParams))
            .then(function(response) {
                return response.data;
            });
        },
        delete: function(ids) {
            return $http.post(baseUrl + 'delete', ids);
        }
    };

    return service;
});