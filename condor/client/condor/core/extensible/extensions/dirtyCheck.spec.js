describe('inprotech.core.extensible.extensions.dirtyCheck', function() {
    'use strict';

    var factory;

    beforeEach(module('inprotech.core.extensible'));

    beforeEach(inject(function(ExtObjFactory) {
        factory = new ExtObjFactory().use(['restorable', 'dirtyCheck', 'savable']);
    }));

    it('should set dirty flag true', function() {
        var context = factory.createContext();
        var extObj = context.attach({
            name: 'n1'
        });

        extObj.name = 'n2';

        expect(extObj.isDirty('name')).toBe(true);
        expect(extObj.isDirty()).toBe(true);
        expect(context.isDirty()).toBe(true);
    });

    it('should get all dirty items', function() {
        var context = factory.createContext();
        var extObj = context.attach({
            name: 'n1'
        });

        extObj.name = 'n2';

        var raw = context.getDirtyItems().map(function(a) {
            return a.getRaw();
        });

        expect(raw).toEqual([{
            name: 'n2'
        }]);
    });

    it('should clear dirty flag after restored', function() {
        var context = factory.createContext();
        var extObj = context.attach({
            name: 'n1'
        });

        extObj.name = 'n2';

        context.restore();

        expect(extObj.isDirty('name')).toBe(false);
        expect(extObj.isDirty()).toBe(false);
        expect(context.isDirty()).toBe(false);
    });

    it('should clear dirty flag after saved', function() {
        var context = factory.createContext();
        var extObj = context.attach({
            name: 'n1'
        });

        extObj.name = 'n2';

        context.save();

        expect(extObj.isDirty('name')).toBe(false);
        expect(extObj.isDirty()).toBe(false);
        expect(context.isDirty()).toBe(false);
    });

    it('should set dirty flag after saved if there are any further changes', function() {
        var context = factory.createContext();
        var extObj = context.attach({
            name: 'n1'
        });

        extObj.name = 'n2';

        context.save();

        extObj.name = 'n1';

        expect(extObj.isDirty('name')).toBe(true);
        expect(extObj.isDirty()).toBe(true);
        expect(context.isDirty()).toBe(true);
    });
});
