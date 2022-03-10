describe('Service inprotech.configuration.general.standinginstructions.characteristics', function() {
    'use strict';
    var service;

    beforeEach(module('inprotech.components.typeahead'));
    beforeEach(inject(function(typeaheadService) {
        service = typeaheadService;
    }));

    describe('findExactMatchItem', function() {
        it('should return item if single result', function() {
            var items = ['a'];

            var item = service.findExactMatchItem(items);

            expect(item).toEqual(items[0]);
        });

        it('should return null if multiple results', function() {
            var items = ['a', 'b'];

            var item = service.findExactMatchItem(items);

            expect(item).toBeFalsy();
        });

        it('should return item with exactMatch flag if multiple results', function() {
            var items = [{
                exactMatch: true,
                value: 'a'
            }, {
                value: 'b'
            }];

            var item = service.findExactMatchItem(items);

            expect(item).toEqual(items[0]);
        });

        it('should be filtering results', function() {
            var items = [{
                id: 1,
                value: 'a'
            }, {
                id: null,
                value: 'b'
            }];

            var filter = function(itm) {
                return itm.id != null;
            };

            var item = service.findExactMatchItem(items, filter);

            expect(item).toEqual(items[0]);

            items = [{
                id: null,
                value: 'b'
            }];

            item = service.findExactMatchItem(items, filter);

            expect(item).toBeFalsy();
        });
    });
});
