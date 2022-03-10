angular.module('inprotech.processing.policing')
    .service('policingQueueFilterService', function() {
        'use strict';

        var getRemovedFilters = function(newData, currentfilterCodes) {
            var newDataCodes = _.pluck(newData, 'code');
            return _.difference(currentfilterCodes, newDataCodes);
        };

        return {
            getFilters: function(column, oldFilters, newData) {
                var filterForField = _.findWhere(oldFilters, {
                    field: column.field
                });

                var filterStringForColumn = filterForField ? filterForField.value : null;

                var filtersForColumn = [];
                if (filterStringForColumn) {
                    filtersForColumn = filterStringForColumn.split(',');
                }

                if (filtersForColumn.length === 0) {
                    return newData;
                }

                var removedFilters = getRemovedFilters(newData, filtersForColumn);

                var filtersToBeAdded = _.chain(column.filterable.dataSource.data())
                    .filter(function(d) {
                        return _.contains(removedFilters, d.code);
                    })
                    .map(function(r) {
                        return {
                            code: r.code,
                            description: r.description
                        };
                    })._wrapped;

                return _.sortBy(_.union(newData, filtersToBeAdded), 'description');
            }
        };
    });
