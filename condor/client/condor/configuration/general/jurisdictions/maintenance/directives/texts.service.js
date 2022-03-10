angular.module('inprotech.configuration.general.jurisdictions').factory('jurisdictionTextsService', function($http) {
    'use strict';
    var baseUrl = 'api/configuration/jurisdictions/maintenance/';

    var service = {
        search: function(queryParams, id) {
            return $http.get(baseUrl + 'texts/' + encodeURIComponent(id), {
                params: {
                    params: JSON.stringify(queryParams)
                }
            }).then(function(response) {
                return response.data;
            });
        }
    };

    return service;
});
