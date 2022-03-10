(function(angular) {
    'use strict';

    angular.module('restmod').factory('ValidationModel', ['restmod', function(restmod) {
        return restmod.mixin(function() {
            this
                .on('before-save', function() {
                    this.$validationerrors = [];
                })
                .on('after-save', function(res) {
                    this.$validationerrors = res.data.errors || [];
                })
                .define('$error', function(key) {
                    if (!key) {
                        return (this.$validationerrors || []).length;
                    }
                    return _.find(this.$validationerrors, {
                        field: key
                    });
                });
        });
    }]);
})(angular);
