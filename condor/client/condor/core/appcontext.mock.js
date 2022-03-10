angular.module('inprotech.mocks.core').factory('appContextMock', ['$q', function($q) {
    'use strict';

    var r = {
        $get: function() {
            return $q.when({});
        },
        then: function(cb) {
            return cb(
                r.returnValue || {}
            );
        }
    };

    return r;
}]);