angular.module('inprotech.core.extensible.extensions').factory('savable', function() {
    'use strict';

    return {
        dependsOn: ['dirtyCheck'],
        initObject: function(extObj) {
            extObj.$ctx.save = {};
            extObj.isSaved = isSaved;
            extObj.save = save;

            extObj.$subscribe('onValueChanged', clearSavedState);
        },

        initContext: function(context) {
            context.save = saveAll;
        }
    };

    function isSaved(key) {
        if (key) {
            return Boolean(this.$ctx.save[key]);
        }

        return Object.keys(this.$ctx.save).length > 0;
    }

    function save() {
        var self = this;
        if (!self.isDirty()) {
            return;
        }

        Object.keys(self.$ctx.dirty).forEach(function(key) {
            self.$ctx.save[key] = true;
        });

        self.$publish('onSaved', self);
    }

    function saveAll() {
        this.$broadcast('save', true);
    }

    function clearSavedState(key) {
        delete this.$ctx.save[key];
    }
});
