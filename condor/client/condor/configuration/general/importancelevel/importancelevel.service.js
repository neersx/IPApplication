angular.module('inprotech.configuration.general.importancelevel')
    .factory('importanceLevelService', ImportanceLevelService);

function ImportanceLevelService($http) {
    'use strict';

    var baseUrl = 'api/configuration/importancelevel/';

    var service = {
        viewData: viewData,
        search: search,
        save: save
    };

    function viewData() {
        return $http.get(baseUrl + 'viewdata').then(function(response) {
            return response.data;
        });
    }

    function search() {
        return $http.get(baseUrl + 'search').then(function(response) {
            return response.data;
        });
    }

    function save(formDelta) {
        return $http.post(baseUrl, formDelta);
    }

    return service;
}