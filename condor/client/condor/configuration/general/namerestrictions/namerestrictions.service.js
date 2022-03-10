angular.module('inprotech.configuration.general.namerestrictions')
    .factory('nameRestrictionsService', NameRestrictionService);


function NameRestrictionService($http) {
    'use strict';

    var baseUrl = 'api/configuration/namerestrictions/';

    var service = {
        viewData: viewData,
        search: search,
        get: get,
        add: add,
        update: update,
        delete: deleteSelected,
        savedNameRestrictionIds: [],
        persistSavedNameRestrictions: persistSavedNameRestrictions,
        markInUseNameRestrictions: markInUseNameRestrictions
    };

    function viewData() {
        return $http.get(baseUrl + 'viewdata').then(function(response) {
            return response.data;
        });
    }

    function search(searchCriteria, queryParams) {
        return $http.get(baseUrl + 'search', {
            params: {
                q: JSON.stringify(searchCriteria),
                params: JSON.stringify(queryParams)
            }
        }).then(function(response) {
            return response.data;
        });
    }

    function get(id) {
        return $http.get(baseUrl + id)
            .then(function(response) {
                return response.data;
            });
    }

    function add(entity) {
        return $http.post(baseUrl, entity);
    }

    function update(entity) {
        return $http.put(baseUrl + entity.id, entity);
    }

    function deleteSelected(selectedNameRestriction) {
        return $http.post(baseUrl + 'delete', {
            ids: _.pluck(selectedNameRestriction, 'id')
        });
    }

    function markInUseNameRestrictions(resultSet, inUseIds) {
        _.each(resultSet, function(nameRestriction) {
            _.each(inUseIds, function(inUseId) {
                if (nameRestriction.id === inUseId) {
                    nameRestriction.inUse = true;
                    nameRestriction.selected = true;
                }
            });
        });
    }

    function persistSavedNameRestrictions(dataSource) {
        _.each(dataSource, function(nameRestriction) {
            _.each(service.savedNameRestrictionIds, function(savedNameRestrictionId) {
                if (nameRestriction.id === savedNameRestrictionId) {
                    nameRestriction.saved = true;
                }
            });
        });
    }

    return service;
}
