angular.module('inprotech.mocks').factory('kendoGridServiceMock', function() {
    'use strict';

    var r = {
        isGridDirty: function() {
            return r.isGridDirty.returnValue;
        },
        sync: angular.noop,
        addOrRestore: angular.noop,
        data: function() {
            return r.data.returnValue;
        },
        activeData: function() {
            return r.activeData.returnValue;
        },
        hasActiveItems: function() {
            return r.hasActiveItems.returnValue || false;
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
