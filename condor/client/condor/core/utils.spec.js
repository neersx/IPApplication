describe('inprotech.core.utils', function() {
    'use strict';

    var service, rootScope;

    beforeEach(module('inprotech.core'));
    beforeEach(inject(function(utils, $rootScope) {
        rootScope = $rootScope;
        service = utils;
    }));

    it('should extend with default values', function() {
        var source = {
            a: 1,
            b: undefined
        };

        var defaults = {
            a: 2,
            b: 2,
            c: 3
        };

        service.extendWithDefaults(source, defaults);

        expect(source).toEqual({
            a: 1,
            b: 2,
            c: 3
        });
    });

    it('cancellable should be able to cancel previous action', function(done) {
        var cancellable = service.cancellable();
        cancellable.promise.then(done);

        cancellable.cancel();
        rootScope.$apply();
    });

    it('steps should proceed when calling next', function() {
        var r;
        service.steps(function(next) {
            next();
        }, function() {
            r = 'ok';
        });
        expect(r).toBe('ok');
    });
});
