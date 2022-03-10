angular.module('inprotech.configuration.general.jurisdictions').factory('jurisdictionStatusFlagsService', function($http, $translate) {
    'use strict';
    var baseUrl = 'api/configuration/jurisdictions/maintenance/';

    var registrationStatus = [{
        key: 1,
        value: $translate.instant('status.pending')
    }, {
        key: 2,
        value: $translate.instant('status.registered')
    }, {
        key: 0,
        value: $translate.instant('status.dead')
    }];

    var service = {
        search: function(queryParams, id) {
            return $http.get(baseUrl + 'statusflags/' + encodeURIComponent(id), {
                params: {
                    params: JSON.stringify(queryParams)
                }
            }).then(function(response) {
                return response.data;
            });
        },
        copyProfiles: getCopyProfiles,
        registrationStatus: registrationStatus
    };

    function getCopyProfiles() {
        return $http.get('api/picklists/CopyProfiles')
            .then(function(response) {
                return response.data;
            });
    } 

    return service;
});