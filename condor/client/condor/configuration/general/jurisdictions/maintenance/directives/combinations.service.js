angular.module('inprotech.configuration.general.jurisdictions').factory('jurisdictionCombinationsService', function($http) {
    'use strict';
    var baseUrl = 'api/configuration/jurisdictions/maintenance/';

    var service = {
        hasCombinations: function(id) {
            return $http.get(baseUrl + 'combinations/' + encodeURIComponent(id)).then(function(response) {
                return response.data;
            });
        }
    };

    return service;
});
