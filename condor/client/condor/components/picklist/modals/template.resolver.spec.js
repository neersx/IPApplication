describe('Service inprotech.components.picklist.templateResolver', function() {
    'use strict';

    beforeEach(module('inprotech.components.picklist'));

    var service;

    beforeEach(inject(function(templateResolver) {
        service = templateResolver;
    }));

    it('should have a resolve method', function() {
        expect(service).toBeDefined();
        expect(service.resolve).toBeDefined();
    });

    it('should build template path by convention', function() {
        var picklistBaseName = 'instructionType';
        expect(service.resolve(picklistBaseName, 'add')).toBe('condor/picklists/instruction-type/instruction-type.html');
    });

    it('should return null if operation is not provided', function() {
        var picklistBaseName = 'instructionType';
        expect(service.resolve(picklistBaseName)).toBeNull();
    });
});
