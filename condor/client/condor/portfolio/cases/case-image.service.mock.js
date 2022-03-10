angular.module('inprotech.mocks').service('CaseImageServiceMock', function() {
    'use strict';
    var result = {
        totalRows: 50,
        columns: [],
        rows: []
    };
    var r = {
        getImage: function() {
            return {
                then: function(cb) {
                    return cb(result);
                }
            };
        },
        setReturnValue: function(val) {
            result = val;
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});