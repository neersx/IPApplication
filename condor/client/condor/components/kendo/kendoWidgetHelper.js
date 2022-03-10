angular.module('inprotech.components.kendo').factory('kendoWidgetHelper', function() {
    'use strict';

    var r = {
        getDataItem: getDataItem,
        getParentDataItem: getParentDataItem,
        getParentDataItemFromData: getParentDataItemFromData
    };

    return r;

    function getDataItem(widget, element) {
        return widget.dataItem(element);
    }

    function getParentDataItem(widget, element) {
        // first parent() get the collection of current node
        // second parent() get the real parent node
        return widget.dataItem(element).parent().parent();
    }

    function getParentDataItemFromData(itemData){
        return itemData.parent().parent();
    }
});
