angular.module('inprotech.mocks.core').factory('promiseMock', function() {
    'use strict';

    var r = {
        createSpy: function(thenReturnData, suppressCallThrough) {
            var mockAlways = jasmine.createSpy('always-spy', function(alwaysCallback) {
                return alwaysCallback();
            });

            var mockThen = jasmine.createSpy('then-spy', function(callback) {
                if (callback === null) {
                    return {
                        always: mockAlways
                    };
                }
                var callbackResult = callback(thenReturnData);
                if (callbackResult != null && callbackResult.then) {
                    return callbackResult;
                }

                return r.createSpy(callbackResult);
            });
            
            if (!suppressCallThrough) {
                mockAlways.and.callThrough();
                mockThen.and.callThrough();
            }

            var returnFn = jasmine.createSpy('spy', function() {
                return {
                    then: mockThen
                };
            }).and.callThrough();

            returnFn.then = mockThen;
            returnFn.data = thenReturnData;
            return returnFn;
        }
    };

    return r;
});
