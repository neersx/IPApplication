angular.module('inprotech.core').factory('comparer', function () {
    'use strict';
    return {
        comparePickList: function (itemA, itemB, key) {
            itemA = itemA == null || itemA[key] == null ? null : itemA;
            itemB = itemB == null || itemB[key] == null ? null : itemB;

            if (itemA === itemB) {
                return true;
            }

            if (itemA == null) {
                return itemB == null;
            }

            if (itemB == null) {
                return itemA == null;
            }

            return itemA[key] === itemB[key];
        }
    }
});