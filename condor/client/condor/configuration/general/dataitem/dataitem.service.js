angular.module('inprotech.configuration.general.dataitem')
    .factory('dataItemService', DataItemService);

function DataItemService($http, LastSearch) {
    'use strict';

    var baseUrl = 'api/configuration/dataitems/';
    var lastCriteria;

    var service = {
        search: function(searchCriteria, queryParams) {
            service.lastSearch = new LastSearch({
                method: search,
                methodName: 'search',
                args: arguments
            });

            return search(searchCriteria, queryParams);
        },
        viewData: viewData,
        getColumnFilterData: getColumnFilterData,
        add: add,
        validate: validate,
        validatePicklistSql: validatePicklistSql,
        savedDataItemIds: [],
        delete: deleteSelected,
        persistSavedDataItems: persistSavedDataItems,
        get: get,
        update: update
    };

    function search(criteria, queryParams) {
        lastCriteria = angular.copy(criteria);

        return $http.get(baseUrl + 'search', {
            params: {
                q: JSON.stringify(criteria),
                params: JSON.stringify(queryParams)
            }
        }).then(function(response) {
            return response.data;
        });
    }

    function viewData() {
        return $http.get(baseUrl + 'viewdata').then(function(response) {
            return response.data;
        });
    }

    function getColumnFilterData(column) {
        return $http.get(baseUrl + 'filterdata/' + column.field, {
            params: {
                criteria: JSON.stringify(lastCriteria)
            }
        }).then(function(response) {
            return response.data;
        });
    }

    function add(entity) {
        return $http.post(baseUrl, entity);
    }

    function validate(entity) {
        return $http.post(baseUrl + 'validate', entity);
    }

    function validatePicklistSql(entity) {
        return $http.post('api/picklists/dataItems/' + 'validate', entity);
    }

    function get(id) {
        return $http.get(baseUrl + id)
            .then(function(response) {
                return response.data;
            });
    }

    function update(entity) {
        return $http.put(baseUrl + entity.id, entity);
    }

    function deleteSelected(selectedDataItems) {
        return $http.post(baseUrl + 'delete', {
            ids: _.pluck(selectedDataItems, 'id')
        });
    }

    function persistSavedDataItems(dataSource) {
        _.each(dataSource, function(dataItem) {
            _.each(service.savedDataItemIds, function(savedDataItemId) {
                if (dataItem.id === savedDataItemId) {
                    dataItem.saved = true;
                }
            });
        });
    }

    return service;
}