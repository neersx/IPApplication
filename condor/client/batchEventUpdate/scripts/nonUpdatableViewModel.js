var batchEventUpdate = (function(my) {
    'use strict';
    my.nonUpdatableViewModel = function(nonUpdatableCaseList) {
        return utils.sortable(nonUpdatableCaseList);
    };
    return my;
}(batchEventUpdate || {}));