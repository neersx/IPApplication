describe('inprotech.components.grid.inlineEdit', function() {
    'use strict';

    var service;
    beforeEach(function() {
        module('inprotech.components.grid');

        inject(function(inlineEdit) {
            service = inlineEdit;
        });
    });

    it('hasError', function() {
        expect(service.hasError([{
            hasError: _.constant(true)
        }])).toBe(true);

        expect(service.hasError([{
            hasError: _.constant(false)
        }])).toBe(false);
    });

    it('canSave', function() {
        expect(service.canSave([{
            added: true
        }])).toBe(true);
        expect(service.canSave([{
            deleted: true
        }])).toBe(true);
        expect(service.canSave([{
            isDirty: _.constant(true)
        }])).toBe(true);
        expect(service.canSave([])).toBe(false);
    });

    describe('defineModel', function() {
        it('init', function() {
            var create = service.defineModel(['id', 'name']);
            expect(create().added).toBe(true);
            var obj = create({
                id: 1,
                name: 'a'
            });
            expect(obj).toEqual(jasmine.objectContaining({
                id: 1,
                name: 'a'
            }));
        });

        it('isDirty', function() {
            var create = service.defineModel(['id', 'name']);
            var obj = create();

            obj.id = 1;
            expect(obj.isDirty('id')).toBe(true);
            expect(obj.isDirty('name')).toBe(false);

            obj = create({
                id: 1,
                name: 'a'
            });
            obj.name = 'b';
            expect(obj.isDirty('id')).toBe(false);
            expect(obj.isDirty('name')).toBe(true);
        });

        it('hasError', function() {
            var create = service.defineModel(['id', 'name']);
            var obj = create();

            obj.error('duplicate', true);
            expect(obj.error('duplicate')).toBe(true);
            expect(obj.hasError()).toBe(true);
        });
    });
});
