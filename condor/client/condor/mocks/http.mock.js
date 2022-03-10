angular.module('inprotech.mocks').factory('httpMock', function() {
    'use strict';

    var http = {
        get: function() {
            return then(http.get.returnValue);
        },
        post: function() {
            return then(http.post.returnValue);
        },
        patch: function() {
            return then(http.patch.returnValue);
        },
        put: function() {
            return then(http.put.returnValue);
        },
        delete: function() {
            return then(http.put.returnValue);
        }
    };

    var then = function(returnValue) {
        return {
            then: function(cb) {
                return cb({
                    data: returnValue
                });
            }
        };
    };

    Object.keys(http).forEach(function(key) {
        if (angular.isFunction(http[key])) {
            spyOn(http, key).and.callThrough();
        }
    });

    return http;
});
