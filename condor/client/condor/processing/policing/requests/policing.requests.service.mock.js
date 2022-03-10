angular.module('inprotech.mocks.processing.policing')
    .factory('PolicingRequestServiceMock', function() {
        var r = {
            savedRequestIds: [],
            uiPersistSavedRequests: angular.noop,
            get: angular.noop,
            getRequest: angular.noop,
            save: angular.noop,
            delete: angular.noop,
            getAffectedCases: angular.noop,
            getNextLettersDate:angular.noop,
            markInUseRequests: angular.noop,
            validateCharacteristics: function() {
                return {
                    then: function(cb) {
                        if (cb) {
                            cb(r.validateCharacteristics.returnValue || []);
                        }
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
