angular.module('inprotech.core.extensible.extensions').factory('restorable', function() {
    'use strict';

    return {
        initObject: function(extObj) {
            copy(extObj);

            extObj.restore = restore;

            extObj.$subscribe('onSaved', function() {
                copy(this);
            });
        },

        initContext: function(context) {
            context.restore = restoreAll;
        }
    };

    function restore() {
        var self = this;

        self.$ctx.obj = angular.copy(self.$ctx.copy);

        self.$publish('onRestored');

        return self;
    }

    function restoreAll() {
        this.$broadcast('restore');
    }

    function copy(extObj) {
        extObj.$ctx.copy = angular.copy(extObj.$ctx.obj);
    }
});
