angular.module('inprotech.components.grid').factory('commonQueryHelper', function(columnFilterHelper) {
    'use strict';

    return {
        buildQueryParams: function(evt, gridOptions) {
            var data = evt.data || {};
            var queryParams = {};

            angular.extend(queryParams, buildSortQueryParams(data.sort));
            angular.extend(queryParams, buildPagingQueryParams(data));
            angular.extend(queryParams, columnFilterHelper.buildQueryParams(data.filter, gridOptions));

            return queryParams;
        }
    };

    function buildSortQueryParams(sort) {
        var queryParams = {};
        if (sort && sort.length) {
            queryParams.sortBy = sort[0].field;
            queryParams.sortDir = sort[0].dir;
        }

        return queryParams;
    }

    function buildPagingQueryParams(data) {
        var queryParams = {};

        if (data.skip != null) {
            queryParams.skip = data.skip;
        }

        if (data.take != null) {
            queryParams.take = data.take;
        }

        return queryParams;
    }
});
