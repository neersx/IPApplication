angular.module('inprotech.core.extensible.extensions').factory('dirtyCheck', function() {
    'use strict';

    return {
        dependsOn: ['restorable'],
        initObject: function(extObj) {
            extObj.$ctx.dirty = {};
            extObj.isDirty = isDirty;
            extObj.getDirtyItems = getDirtyItems;
            extObj.setDirty = setDirty;

            extObj.$subscribe('onValueChanged', onValueChanged);

            extObj.$subscribe('onRestored', setPristine);

            extObj.$subscribe('onSaved', setPristine);

            extObj.$subscribe('onDirtyChanged', function(dirty) {
                var context = extObj.$ctx.parent;
                if (!context) {
                    return;
                }

                var oldDirty = context.isDirty();

                if (dirty) {
                    context.$ctx.dirtyCount++;
                } else {
                    context.$ctx.dirtyCount--;
                }

                var newDirty = context.isDirty();

                if (oldDirty !== newDirty) {
                    context.$publish('onDirtyChanged', newDirty);
                }
            });
        },

        initContext: function(context) {
            context.$ctx.dirtyCount = 0;

            context.isDirty = function() {
                return context.$ctx.dirtyCount > 0;
            };

            context.getDirtyItems = function() {
                return context.getItems().filter(function(item) {
                    return item.isDirty();
                });
            };
        }
    };

    function isDirty(key) {
        var self = this;
        if (key) {
            return !!self.$ctx.dirty[key];
        }

        return Object.keys(self.$ctx.dirty).length > 0;
    }

    function setDirty(key, dirty) {
        if (key) {
            var oldDirty = this.isDirty();
            if (dirty == oldDirty) return;

            if (dirty) {
                this.$ctx.dirty[key] = true;
            } else {
                delete this.$ctx.dirty[key];
            }

            var newDirty = this.isDirty();

            if (oldDirty !== newDirty) {
                this.$publish('onDirtyChanged', newDirty);
            }
        }
    }    

    function getDirtyItems() {
        var self = this;
        return self.$ctx.dirty;
    }

    function onValueChanged(key, val) {
        var dirty;
        if (this.$equals) {
            var same = this.$equals(key, val, this.$ctx.copy[key]);
            if (same != null) {
                dirty = !same;
            }
        }

        if (dirty == null) {
            dirty = !angular.equals(val, this.$ctx.copy[key]);
        }

        var oldDirty = this.isDirty();

        if (dirty) {
            this.$ctx.dirty[key] = true;
        } else {
            delete this.$ctx.dirty[key];
        }

        var newDirty = this.isDirty();

        if (oldDirty !== newDirty) {
            this.$publish('onDirtyChanged', newDirty);
        }
    }

    function setPristine() {
        if (!this.isDirty()) {
            return;
        }

        this.$ctx.dirty = {};

        this.$publish('onDirtyChanged', false);
    }
});