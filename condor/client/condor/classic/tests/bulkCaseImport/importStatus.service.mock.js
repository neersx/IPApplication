angular.module('inprotech.mocks.core')
    .service('importStatusServiceMock', function() {
        'use strict';

        var r = {
            getImportStatus: function() {
                return {
                    then: function(cb) {
                        return cb(r.getImportStatus.returnValue);
                    }
                };
            },
            getBatchSummaryView: function() {
                return {
                    then: function(cb) {
                        return cb(r.getBatchSummaryView.returnValue);
                    }
                };
            }
        };

        Object.keys(r).forEach(function(key) {
            if (angular.isFunction(r[key])) {
                spyOn(r, key).and.callThrough();
            }
        });

        return r;
    });