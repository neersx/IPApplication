angular.module('inprotech.configuration.general.jurisdictions').factory('jurisdictionsService', function($http, LastSearch, store) {
    'use strict';
    var baseUrl = 'api/configuration/jurisdictions/';
    var lastCriteria;

    var service = {
        search: function(searchCriteria, queryParams) {
            service.lastSearch = new LastSearch({
                method: search,
                methodName: 'search',
                args: arguments
            });
            store.local.set('lastSearch', arguments);

            return search(searchCriteria, queryParams);
        },
        getColumnFilterData: function(column) {
            var c = buildQuery(lastCriteria);
            return $http.get(baseUrl + 'filterdata/' + column.field, {
                params: {
                    criteria: JSON.stringify(c)
                }
            }).then(function(response) {
                return response.data;
            });
        },
        initialData: initialData,
        newId: null
    };
    return service;

    function buildQuery(criteria) {
        return {
            text: criteria.text || ''
        };
    }

    function search(criteria, queryParams) {
        lastCriteria = angular.copy(criteria);
        var q = buildQuery(criteria);

        return $http.get(baseUrl + 'search', {
            params: {
                q: JSON.stringify(q),
                params: JSON.stringify(queryParams)
            }
        }).then(function(response) {
            return response.data;
        });
    }

    function initialData() {
        return $http.get('api/configuration/jurisdictions/view').then(function(response) {
            return response.data;
        });
    }
});