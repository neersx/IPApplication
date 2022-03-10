angular.module('inprotech.configuration.general.standinginstructions').factory('AssignedArray', function(ArrayExt, ObjectExt) {
    'use strict';

    function AssignedArray(sentItems) {
        var self = this;

        if (!sentItems) {
            sentItems = [];
        }

        self.safeCopy = _.map(sentItems, function(obj) {
            return _.extend({}, obj);
        });

        self.items = sentItems;
        angular.forEach(self.items, function(item, idx) {
            if (!(item instanceof ObjectExt)) {
                self.items[idx] = new ObjectExt(item);
            }
        });
    }

    AssignedArray.prototype = new ArrayExt();

    _.extend(AssignedArray.prototype, {
        mergeByProperty: function(destArray) {
            var self = this;

            _.each(destArray.items, function(dObj) {
                var obj = _.find(self.items, function(sObj) {
                    return dObj.obj.id === sObj.obj.id;
                });

                if (obj) {
                    _.extend(dObj.obj, obj.obj);
                } else {
                    var newItem = self.addNew({
                        id: dObj.obj.id,
                        selected: false
                    });
                    newItem.status = 'none';
                    _.extend(dObj.obj, newItem.obj);
                }
            });
        },

        revert: function() {
            var self = this;
            var copiedItems = new AssignedArray(angular.copy(self.safeCopy)).items;

            _.each(copiedItems, function(c) {
                c.isSaved = self.isSaved(c.obj.id);
            });

            self.clear();
            self.items = copiedItems;
        },

        isDirty: function() {
            var self = this;

            return _.any(self.items, function(c) {
                return c.status && c.status !== 'none';
            });
        },

        sanitize: function(validIds) {
            var self = this;

            self.items = _.filter(self.items, function(i) {
                return _.contains(validIds, i.obj.id);
            });
        },

        setValue: function(id, value, isReverted) {
            var self = this;

            var assigned = self.pushOrGet('id', id);
            assigned.obj.selected = value;
            assigned.changeStatus(isReverted);
        },

        isUpdated: function(id) {
            var self = this;
            var object = self.get('id', id);

            return object ? object.status !== 'none' : false;
        },

        isSaved: function(id) {
            var self = this;

            var object = self.get('id', id);

            return object ? object.isSaved : false;
        }
    });

    return AssignedArray;
});
