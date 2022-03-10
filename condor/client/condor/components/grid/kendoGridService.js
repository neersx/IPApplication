angular.module('inprotech.components.grid').service('kendoGridService', function() {
    'use strict';
    var s = {
        isGridDirty: isGridDirty,
        sync: sync,
        data: data,
        activeData: activeData,
        hasActiveItems: hasActiveItems
    };

    return s;

    function isGridDirty(gridOptions) {
        var data = s.data(gridOptions);
        return data && _.any(data, function(item) {
            return item.added || item.isAdded || item.isEdited || item.deleted;
        });
    }

    function sync(gridOptions, syncItems, itemMap) {
        var data = s.data(gridOptions);

        var upperLimit = data.length;
        var limiter = 0;

        var i = 0;
        // use while loop because we are reducing the array as we iterate
        while (data[i] && limiter < upperLimit) {
            var item = data[i];
            if (item.isAdded || item.added) {
                gridOptions.dataSource.remove(item);
            } else {
                item.deleted = true;
                i++;
            }
            limiter++;
        }

        addOrRestore(gridOptions, syncItems, itemMap);
    }

    function addOrRestore(gridOptions, selectedItems, itemMap) {
        itemMap = itemMap || {
            key: 'key',
            value: 'value'
        };
        var gridData = s.data(gridOptions);
        _.each(selectedItems, function(item) {

            var found = _.find(gridData, function(i) {
                return i[itemMap.key] === item[itemMap.key];
            });

            if (found && found.deleted) {
                found.deleted = false;
            }

            if (!found) {
                var itemToAdd = {};
                itemToAdd[itemMap.key] = item[itemMap.key];
                itemToAdd[itemMap.value] = item[itemMap.value];
                gridOptions.dataSource.add(_.extend({
                    isAdded: true,
                    deleted: false
                }, itemToAdd));
            }
        });
    }

    function data(gridOptions) {
        return gridOptions.dataSource.data();
    }

    function activeData(gridOptions) {
        return _.reject(s.data(gridOptions), function(item) {
            return item.deleted;
        });
    }

    function hasActiveItems(gridOptions) {
        return s.activeData(gridOptions).length > 0;
    }
});
