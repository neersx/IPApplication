describe('inprotech.core.extensible.extensions.validatable', function() {
    'use strict';

    var factory;

    beforeEach(module('inprotech.core.extensible'));

    beforeEach(inject(function(ExtObjFactory) {
        factory = new ExtObjFactory().use(['validatable']);
    }));

    it('should set error flag', function() {
        var context = factory.createContext();
        var extObj = context.attach({
            name: 'n1'
        });

        extObj.hasError('name', true);

        expect(extObj.hasError('name')).toBe(true);
        expect(context.hasError()).toBe(true);

        extObj.hasError('name', false);

        expect(extObj.hasError('name')).toBe(false);
        expect(context.hasError()).toBe(false);
    });
});
