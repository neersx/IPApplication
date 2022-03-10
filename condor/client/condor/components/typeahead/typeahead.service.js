angular.module('inprotech.components.typeahead').factory('typeaheadService', function() {
    'use strict';

    return {
        findExactMatchItem: function(items, filter) {
            if (!items) {
                return null;
            }

            if (filter) {
                items = _.filter(items, filter);
            }

            var matchCount = items.length;
            var item = null;

            if (matchCount === 1) {
                item = items[0];
            } else if (matchCount > 1) {
                item = _.find(items, {
                    exactMatch: true
                });
            }

            return item;
        }
    };
});
