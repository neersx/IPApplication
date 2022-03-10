(function() {
    'use strict';
    angular.module('inprotech.api.extensions')
        .factory('ignoreAttributes', function(restmod) {
            return restmod.mixin({
                error: {
                    mask: true
                },
                 marked: {
                    mask: true
                }
            });
        });
})();
