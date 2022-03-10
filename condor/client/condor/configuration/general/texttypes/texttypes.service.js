angular.module('inprotech.configuration.general.texttypes')
    .factory('textTypesService', textTypesService);


function textTypesService($http) {
    'use strict';

    var baseUrl = 'api/configuration/texttypes/';

    var service = {
        viewData: viewData,
        search: search,
        searchResults: [],
        find: find,
        get: get,
        add: add,
        update: update,
        delete: deleteSelected,
        savedTextTypeIds: [],
        resetSavedValue: resetSavedValue,
        markInUseTextTypes: markInUseTextTypes,
        persistSavedTextTypes: persistSavedTextTypes,
        changeTextTypeCode: changeTextTypeCode
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
        });
    }

    function deleteSelected(item) {
        return $http.post(baseUrl + 'delete', {
            ids: _.pluck(item, 'id')
        });
    }

    function markInUseTextTypes(resultSet, inUseIds) {
        _.each(resultSet, function(textType) {
            _.each(inUseIds, function(inUseId) {
                if (textType.id === inUseId) {
                    textType.inUse = true;
                    textType.selected = true;
                }
            });
        });
    }

    function find(id) {
        return _.find(service.searchResults.data, function(item) {
            return item.id === id;
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

    function changeTextTypeCode(entity) {
        return $http.put(baseUrl + entity.id + '/texttypecode', entity);
    }

    function resetSavedValue(id) {
        _.each(service.searchResults, function(textType) {
            if (textType.id === id) {
                textType.saved = false;
            }
        });
    }

    function persistSavedTextTypes() {
        _.each(service.searchResults, function(textType) {
            _.each(service.savedTextTypeIds, function(savedTextTypeId) {
                if (textType.id === savedTextTypeId) {
                    textType.saved = true;
                }
            });
        });
    }

    return service;
}
