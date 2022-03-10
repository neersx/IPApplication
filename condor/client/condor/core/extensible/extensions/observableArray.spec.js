describe('inprotech.core.extensible.extensions.observableArray', function() {
    'use strict';

    var factory;

    beforeEach(module('inprotech.core.extensible'));

    beforeEach(inject(function(ExtObjFactory) {
        factory = new ExtObjFactory().use(['restorable', 'dirtyCheck', 'savable', 'observableArray']);
    }));

    it('should set dirty flag true', function() {
        var context = factory.createContext();
        var extObj = context.attach({
            tags: ['t1']
        });

        extObj.tags.push('t2');

        expect(extObj.isDirty('tags')).toBe(true);
        expect(extObj.isDirty()).toBe(true);
        expect(context.isDirty()).toBe(true);
    });

    it('should set dirty flag false if collection is still the same', function() {
        var context = factory.createContext();
        var extObj = context.attach({
            tags: ['t1']
        });

        extObj.tags.push('t2');
        extObj.tags.pop('t2');

        expect(extObj.isDirty('tags')).toBe(false);
    });

    it('should set dirty flag after restored', function() {
        var context = factory.createContext();
        var extObj = context.attach({
            tags: ['t1']
        });

        extObj.tags.push('t2');

        context.restore();

        expect(extObj.isDirty('tags')).toBe(false);

        extObj.tags.push('t2');

        expect(extObj.isDirty('tags')).toBe(true);
    });

    it('should set dirty flag after saved', function() {
        var context = factory.createContext();
        var extObj = context.attach({
            tags: ['t1']
        });

        extObj.tags.push('t2');

        context.save();

        expect(extObj.isDirty('tags')).toBe(false);

        extObj.tags.push('t3');

        expect(extObj.isDirty('tags')).toBe(true);
    });
});
