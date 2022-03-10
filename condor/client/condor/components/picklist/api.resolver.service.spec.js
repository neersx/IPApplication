describe('Service inprotech.components.picklist.apiResolverService', function() {
    'use strict';

    beforeEach(module('inprotech.components.picklist'));

    var service, api = {};

    beforeEach(module(function($provide) {
        $provide.value('SomeApi', api);
    }));

    beforeEach(inject(function(apiResolverService) {
        service = apiResolverService;
    }));

    it('should have a resolve method', function() {
        expect(service).toBeDefined();
        expect(service.resolve).toBeDefined();
    });

    it('should return api if exists', function() {
        expect(service.resolve('Some')).toBe(api);
    });

    it('should return null if not exists', function() {
        expect(service.resolve('SomeOther')).not.toBe(api);
    });
});
