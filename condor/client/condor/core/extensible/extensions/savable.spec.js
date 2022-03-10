describe('inprotech.core.extensible.extensions.savable', function() {
    'use strict';

    var factory;

    beforeEach(module('inprotech.core.extensible'));

    beforeEach(inject(function(ExtObjFactory) {
        factory = new ExtObjFactory().use(['restorable', 'dirtyCheck', 'savable']);
    }));

    it('should set isSaved flag true', function() {
        var context = factory.createContext();
        var extObj1 = context.attach({
            name: 'n1'
        });
        var extObj2 = context.attach({
            name: 'n2'
        });

        extObj1.name = 'n1a';
        extObj1.save();

        extObj2.name = 'n2a';
        extObj2.save();

        expect(extObj1.isSaved('name')).toBe(true);
        expect(extObj2.isSaved('name')).toBe(true);
    });
});
