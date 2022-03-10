angular.module('inprotech.mocks.processing.policing')
    .factory('policingRequestAffectedCasesServiceMock', function() {
        var r = {
            getAffectedCases: angular.noop
        };

        Object.keys(r).forEach(function(key) {
            if (angular.isFunction(r[key])) {
                spyOn(r, key).and.callThrough();
            }
        });
        return r;
    });