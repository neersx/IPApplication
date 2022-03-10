angular.module('inprotech.configuration.general.nametypes')
    .factory('nameTypesService', NameTypesService);


function NameTypesService($http) {
    'use strict';

    var baseUrl = 'api/configuration/nametypes/';

    var service = {
        viewData: viewData,
        search: search,
        get: get,
        add: add,
        update: update,
        delete: deleteSelected,
        savedNameTypeIds: [],
        persistSavedNameTypes: persistSavedNameTypes,
        markInUseNameTypes: markInUseNameTypes,
        updateNameTypesSequence: updateNameTypesSequence
    };

    function viewData() {
        return $http.get(baseUrl + 'viewdata').then(function(response) {
            return response.data;
        });
    }

    function search(searchCriteria) {
        return $http.get(baseUrl + 'search', {
            params: {
                q: JSON.stringify(searchCriteria)
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

    function deleteSelected(selectedNameTypes) {
        return $http.post(baseUrl + 'delete', {
            ids: _.pluck(selectedNameTypes, 'id')
        });
    }

    function updateNameTypesSequence(saveDetail) {
        var apiUrl = baseUrl + 'updatenametypessequence';
        return $http.put(apiUrl, saveDetail);
    }

    function markInUseNameTypes(resultSet, inUseIds) {
        _.each(resultSet, function(nameType) {
            _.each(inUseIds, function(inUseId) {
                if (nameType.id === inUseId) {
                    nameType.inUse = true;
                    nameType.selected = true;
                }
            });
        });
    }

    function persistSavedNameTypes(dataSource) {
        _.each(dataSource, function(nameType) {
            _.each(service.savedNameTypeIds, function(savedNameTypeId) {
                if (nameType.id === savedNameTypeId) {
                    nameType.saved = true;
                }
            });
        });
    }

    return service;
}