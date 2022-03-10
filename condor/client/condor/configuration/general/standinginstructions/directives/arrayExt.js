angular.module('inprotech.configuration.general.standinginstructions').factory('ArrayExt', function(ObjectExt) {
    'use strict';

    function ArrayExt(items) {
        var self = this;

        if (!items) {
            items = [];
        }
        self.items = items;
        angular.forEach(this.items, function(item, idx) {
            if (!(item instanceof ObjectExt)) {
                self.items[idx] = new ObjectExt(item);
            }
        });
    }

    ArrayExt.prototype = {
        length: function() {
            var self = this;

            return self.items.length;
        },

        clear: function() {
            var self = this;

            _.each(_.range(self.items.length), function(idx) {
                delete self.items[idx];
            });
        },

        addNew: function(object) {
            var self = this;

            var newObj = new ObjectExt(object).setNew();
            self.items.push(newObj);

            return newObj;
        },

        anyAdditions: function() {
            var self = this;
            var count = 0;
            _.each(self.items, function(i) {
                if (i.status === 'added' && !i.isDeleted) {
                    count++;
                }
            });
            return count > 0;
        },

        setSavedState: function(arr, prop) {
            if (!arr || arr.length === 0) {
                return;
            }
            var self = this;
            _.each(arr.items, function(arr2obj) {
                var obj = _.find(self.items, function(arr1obj) {
                    return arr1obj.obj[prop] === arr2obj.obj[prop];
                });

                if (obj) {
                    obj.isSaved = arr2obj.isSaved;
                }
            });
        },

        setError: function(errors) {
            var self = this;

            _.each(errors, function(e) {
                var id;
                if (!isNaN(e.id)) {
                    id = +e.id;
                } else {
                    id = e.id;
                }
                var item = self.get('id', id);
                if (item) {
                    item.setError(e.message);
                }
            });
        },

        revertAll: function() {
            var self = this;

            _.each(self.items, function(i) {
                i.changeStatus(true);
            });

            self.removeItems('added');
            self.undoDelete();
        },

        removeItems: function(val) {
            var self = this;
            self.items = _.filter(self.items, function(c) {
                return c.status !== val;
            });
        },

        undoDelete: function() {
            _.each(this.items, function(i) {
                i.isDeleted = false;
            });
        },

        getChanges: function() {
            var self = this;
            var changes = {
                added: [],
                updated: [],
                deleted: []
            };
            _.each(self.items, function(i) {
                if (i.isDeleted && i.status !== 'added') {
                    changes.deleted.push(i.getObj());
                } else if (i.status === 'added' && !i.isDeleted) {
                    changes.added.push(i.getObj());
                } else if (i.status === 'updated' && !i.isDeleted) {
                    changes.updated.push(i.getObj());
                }
            });
            return changes;
        },

        checkUniqueness: function(prop, val) {
            var self = this;
            if (!prop) {
                return false;
            }

            var foundElem = _.filter(self.items, function(e) {
                return e.obj[prop] === val && !e.isDeleted;
            });

            if (foundElem && foundElem.length > 1) {
                return false;
            }
            return true;
        },

        getValidIds: function() {
            var self = this;

            var validIds = [];

            _.each(self.items, function(i) {
                if (!i.isDeleted) {
                    validIds.push(i.obj.id);
                }
            });

            return validIds;
        },

        pushOrGet: function(prop, val) {
            var self = this;

            var obj = self.get(prop, val);

            if (!obj) {
                var o = {};
                o[prop] = val;
                obj = self.addNew(o);
            }

            return obj;
        },

        get: function(prop, val) {
            var self = this;

            return _.find(self.items, function(c) {
                return c.obj[prop] === val;
            });
        }
    };
    return ArrayExt;
});
