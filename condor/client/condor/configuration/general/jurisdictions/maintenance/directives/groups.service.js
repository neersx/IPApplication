angular.module('inprotech.configuration.general.jurisdictions').factory('jurisdictionGroupsService', function($http) {
    'use strict';
    var baseUrl = 'api/configuration/jurisdictions/maintenance/';

    var service = {
        search: function(queryParams, id, type) {
            return $http.get(baseUrl + type + '/' + encodeURIComponent(id), {
                params: {
                    params: JSON.stringify(queryParams)
                }
            }).then(function(response) {
                return response.data;
            });
        },
        lastSearchedOnGroups: false
    };

    return service;
});
