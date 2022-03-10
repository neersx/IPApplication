describe('inprotech.core.extensible.extensions.restorable', function() {
    'use strict';

    var factory;

    beforeEach(module('inprotech.core.extensible'));

    beforeEach(inject(function(ExtObjFactory) {
        factory = new ExtObjFactory().use(['restorable']);
    }));

    it('should restore old value', function() {
        var extObj = factory.createObj({
            name: 'n1'
        });

        extObj.name = 'n2';
        extObj.restore();

        expect(extObj.name).toBe('n1');
    });
});
