angular.module('inprotech.configuration.general.numbertypes')
    .factory('numberTypesService', NumberTypesService);


function NumberTypesService($http) {
    'use strict';

    var baseUrl = 'api/configuration/numbertypes/';

    var service = {
        viewData: viewData,
        search: search,
        get: get,
        add: add,
        update: update,
        delete: deleteSelected,
        savedNumberTypeIds: [],
        persistSavedNumberTypes: persistSavedNumberTypes,
        markInUseNumberTypes: markInUseNumberTypes,
        updateNumberTypesSequence: updateNumberTypesSequence,
        changeNumberTypeCode: changeNumberTypeCode
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

    function updateNumberTypesSequence(saveDetail) {
        var apiUrl = baseUrl + 'update-number-types-sequence';
        return $http.put(apiUrl, saveDetail);
    }

    function add(entity) {
        return $http.post(baseUrl, entity);
    }

    function update(entity) {
        return $http.put(baseUrl + entity.id, entity);
    }

    function deleteSelected(selectedNumberTypes) {
        return $http.post(baseUrl + 'delete', {
            ids: _.pluck(selectedNumberTypes, 'id')
        });
    }

    function changeNumberTypeCode(entity) {
        return $http.put(baseUrl + entity.id + '/numbertypecode', entity);
    }

    function markInUseNumberTypes(resultSet, inUseIds) {
        _.each(resultSet, function(numberType) {
            _.each(inUseIds, function(inUseId) {
                if (numberType.id === inUseId) {
                    numberType.inUse = true;
                    numberType.selected = true;
                }
            });
        });
    }

    function persistSavedNumberTypes(dataSource) {
        _.each(dataSource, function(numberType) {
            _.each(service.savedNumberTypeIds, function(savedNumberTypeId) {
                if (numberType.id === savedNumberTypeId) {
                    numberType.saved = true;
                }
            });
        });
    }

    return service;
}