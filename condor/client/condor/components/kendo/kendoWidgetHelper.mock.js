angular.module('inprotech.mocks.components.kendo').factory('kendoWidgetHelperMock', function() {
    'use strict';

    var r = {
        getDataItem: function() {
            return r.getDataItem.returnValue;
        },
        getParentDataItem: function() {
            return r.getParentDataItem.returnValue;
        },
        getParentDataItemFromData: function(){
            return r.getParentDataItemFromData.returnValue;
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
