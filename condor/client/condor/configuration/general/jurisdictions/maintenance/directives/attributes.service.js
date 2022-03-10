angular.module('inprotech.configuration.general.jurisdictions').factory('jurisdictionAttributesService', function($http) {
    'use strict';
    var baseUrl = 'api/configuration/jurisdictions/maintenance/';

    function getAttributeTypes() {
        return $http.get('api/picklists/JurisdictionAttributeTypes')
            .then(function(response) {
                return response.data;
            });
    }

    function getAttributes(typeId) {
        return $http.get('api/picklists/tablecodes?tableType=' + typeId)
            .then(function(response) {
                return response.data;
            });
    }

    var service = {
        listAttributes: function(queryParams, id) {
            return $http.get(baseUrl + 'attributes/' + encodeURIComponent(id), {
                params: {
                    params: JSON.stringify(queryParams)
                }
            }).then(function(response) {
                return response.data;
            });
        },
        getAttributeTypes: getAttributeTypes,
        getAttributes: getAttributes
    };

    return service;
});