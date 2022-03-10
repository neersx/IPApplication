angular.module('inprotech.components.bulkactions').factory('menuSelection', function (commonActions, bus) {
    'use strict';
    return {
        updatePaginationInfo: function (context, paging, pageSize) {
            bus.channel('bulkactions-selection-service')
                .broadcast({
                    type: 'updatePaginationInfo',
                    context: context,
                    paging: paging,
                    pageSize: pageSize
                });
        },
        update: function (context, count, selected, pageSelected) {
            bus.channel('bulkactions-selection-service')
                .broadcast({
                    type: 'update',
                    context: context,
                    totalCount: count,
                    selected: selected,
                    pageSelected: pageSelected
                });
        },
        updateData: function (context, totalCount, currentCount, selected, pageSelected) {
            bus.channel('bulkactions-selection-service')
                .broadcast({
                    type: 'update',
                    context: context,
                    totalCount: totalCount !== null ? totalCount : currentCount,
                    currentCount: currentCount,
                    selected: selected,
                    pageSelected: pageSelected
                });
        },
        reset: function (context) {
            bus.channel('bulkactions-selection-service')
                .broadcast({
                    context: context,
                    type: 'reset'
                });
        }
    };
});
