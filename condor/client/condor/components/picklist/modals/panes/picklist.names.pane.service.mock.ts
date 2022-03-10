angular.module('inprotech.mocks').service('PicklistNamesPaneServiceMock', function() {
    'use strict';
    let result = {
        totalRows: 50,
        columns: [],
        rows: []
    };
    let r = {
        getName: function() {
            return {
                then: function(cb) {
                    return cb(result);
                }
            };
        },
        setReturnValue: function(val) {
            result = val;
        },
    };

    spyOn(r, 'getName').and.callThrough();
    spyOn(r, 'setReturnValue').and.callThrough();

    return r;
});