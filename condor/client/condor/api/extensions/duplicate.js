(function(angular) {
    'use strict';

    angular.module('restmod').factory('DuplicateModel', ['restmod', function(restmod) {
        return restmod.mixin(function() {
            this.define('$duplicate', function(_exclude) {
                var result = {};
                this.$action(function() {
                    var m = this.$type;
                    this.$each(function(value, key) {
                        var meta = m.$$getDescription(key);
                        var notExcluded = _exclude && _exclude.indexOf(key) === -1 || !_exclude;
                        if ((!meta || !meta.relation) && notExcluded) {
                            result[key] = angular.copy(value);
                        }
                    }); 
                    return result;
                });
                return result;
            });
        });
    }]);
})(angular);
