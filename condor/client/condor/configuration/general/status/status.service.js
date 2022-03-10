angular.module('inprotech.configuration.general.status')
    .factory('statusService', StatusService);


function StatusService($http) {
    'use strict';

    var baseUrl = 'api/configuration/status/';

    var service = {
        search: search,
        supportData: supportData,
        get: get,
        add: add,
        update: update,
        delete: deleteSelected,
        markInUseStatuses: markInUseStatuses,
        savedStatusIds: [],
        persistSavedStatuses: persistSavedStatuses
    };

    return service;

    function supportData() {
        return $http.get('api/configuration/status/supportdata').then(function(response) {
            return response.data;
        });
    }

    function search(searchCriteria) {
        var q = {
            text: searchCriteria.text || '',
            isRenewal: searchCriteria.isRenewal
        };

        return $http.get('api/configuration/status', {
            params: {
                q: JSON.stringify(q)
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

    function deleteSelected(selectedStatuses) {
        return $http.post('api/configuration/status/' + 'delete', {
            ids: _.pluck(selectedStatuses, 'id')
        });
    }

    function markInUseStatuses(gridData, inUseIds) {
        _.each(gridData, function(status) {
            _.each(inUseIds, function(inUseId) {
                if (status.id === inUseId) {
                    status.inUse = true;
                    status.selected = true;
                }
            });
        });
    }

    function persistSavedStatuses(gridData) {
        _.each(gridData, function(status) {
            _.each(service.savedStatusIds, function(savedStatusId) {
                if (status.id === savedStatusId) {
                    status.saved = true;
                }
            });
        });
    }
}