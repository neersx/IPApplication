angular.module('inprotech.configuration.rules.workflows').factory('workflowsSearchService', function ($http, characteristicsBuilder, sharedService, LastSearch, store,$q) {
    'use strict';

    return {
        search: function (searchCriteria, queryParams) {
            sharedService.lastSearch = new LastSearch({
                method: search,
                methodName: 'search',
                args: arguments
            });
            store.local.set('lastSearch', arguments);
            return search(searchCriteria, queryParams);
        },

        searchByIds: function (selectedCriteria, queryParams) {
            sharedService.lastSearch = new LastSearch({
                method: searchByIds,
                methodName: 'searchByIds',
                args: arguments
            });
            store.local.set('lastSearch', arguments);
            return searchByIds(selectedCriteria, queryParams);
        },

        getColumnFilterData: function (column, columnFilters) {
            if(sharedService.lastSearch){
            switch (sharedService.lastSearch.methodName) {
                case 'search':
                    var c = characteristicsBuilder.build(sharedService.lastSearch.args[0]);

                    return $http.get('api/configuration/rules/workflows/filterdata/' + column.field, {
                        params: {
                            criteria: JSON.stringify(c),
                            columnFilters: JSON.stringify(columnFilters)
                        }
                    }).then(function (response) {
                        return response.data;
                    });
                case 'searchByIds':
                    var ids = _.pluck(sharedService.lastSearch.args[0], 'id');

                    return $http.get('api/configuration/rules/workflows/filterdatabyids/' + column.field, {
                        params: {
                            q: JSON.stringify(ids),
                            columnFilters: JSON.stringify(columnFilters)
                        }
                    }).then(function (response) {
                        return response.data;
                    });
            }
        }else{
            var deferred = $q.defer();
            deferred.resolve([]);
            return deferred.promise;
        }
        },

        getCaseCharacteristics: function (caseId) {
            return $http.get('api/configuration/rules/characteristics/caseCharacteristics/' + encodeURIComponent(caseId) + '?purposeCode=E')
                .then(function (response) {
                    return response.data;
                });
        },

        getDefaultDateOfLaw: function (caseId, actionId) {
            return $http.get('api/configuration/rules/workflows/defaultDateOfLaw', {
                params: {
                    caseId: caseId,
                    actionId: actionId
                }
            })
                .then(function (response) {
                    return response.data;
                });
        }
    };

    function search(searchCriteria, queryParams) {
        var c = characteristicsBuilder.build(searchCriteria);

        return $http.get('api/configuration/rules/workflows/search', {
            params: {
                criteria: JSON.stringify(c),
                params: JSON.stringify(queryParams)
            }
        }).then(function (response) {
            return response.data;
        });
    }

    function searchByIds(selectedCriteria, queryParams) {
        var ids = _.pluck(selectedCriteria, 'id');

        return $http.get('api/configuration/rules/workflows/searchByIds', {
            params: {
                q: JSON.stringify(ids),
                params: JSON.stringify(queryParams)
            }
        }).then(function (response) {
            return response.data;
        });
    }
});
