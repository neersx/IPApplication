angular.module('inprotech.components.page').service('pagerHelperService', function() {
    'use strict';

    return {
        getPageForId: getPageForId
    };

    function getPageForId(ids, id, pageSize) {
        if (!pageSize || !ids || angular.isUndefined(id)) {
            return {
                page: -1,
                relativeRowIndex: -1
            };
        }

        if (ids.length > pageSize) {
            var index = 0;
            if (isNaN(id) || isNaN(ids[0])) {
                index = _.indexOf(ids, id);
            } else {
                index = _.indexOf(ids, parseInt(id));
            }

            if (index !== -1) {
                return {
                    page: Math.floor(index / pageSize) + 1,
                    relativeRowIndex: (index % pageSize)
                };
            }
            return {
                page: -1,
                relativeRowIndex: -1
            };
        }

        var idIndex = _.indexOf(ids, id);

        return {
            page: idIndex === -1 ? -1 : 1,
            relativeRowIndex: idIndex
        };
    }
});