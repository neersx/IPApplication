angular.module('inprotech.mocks').service('CaseViewServiceMock', function() {
    'use strict';
    var result = {
        totalRows: 50,
        columns: [],
        rows: []
    };
    var r = {
        getOverview: function() {
            return {
                then: function(cb) {
                    return cb(result);
                }
            };
        },
        getPropertyTypeIcon: function() {
            return {
                then: function(cb) {
                    return cb(r.getPropertyTypeIcon.returnValue);
                }
            };
        },
        getImportanceLevelAndEventNoteTypes: function() {
            return {
                then: function(cb) {
                    return cb(r.getImportanceLevelAndEventNoteTypes.returnValue)
                }
            };
        },
        getScreenControl: function() {
            return {
                then: function(cb) {
                    return cb(r.getScreenControl.returnValue)
                }
            };
        },
        getIppAvailability: function() {
            return {
                them: function(cb) {
                    return cb(r.getIppAvailability.returnValue);
                }
            }
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});