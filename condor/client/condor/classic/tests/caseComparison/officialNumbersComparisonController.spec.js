'use strict';

describe('Inprotech.CaseDataComparison.officialNumbersComparisonController', function() {

    beforeEach(module('Inprotech.CaseDataComparison'));

    var fixture = {};

    var buildItem = function() {
        return {
            id: 1,
            number: {
                updated: false
            },
            eventDate: {
                updated: false
            }
        };
    };

    beforeEach(
        inject(
            function($controller, $rootScope) {
                fixture = {
                    controller: function() {
                        fixture.scope = $rootScope.$new();
                        return $controller('officialNumbersComparisonController', {
                            $scope: fixture.scope
                        });
                    }
                };
            }
        )
    );

    it('toggles date off when number toggled off', function() {

        var item = buildItem();

        item.number.updated = false;
        item.eventDate.updated = true;

        item.id = null;

        fixture.controller();
        fixture.scope.toggleNumberSelection(item);
        expect(item.number.updated).toBe(false);
        expect(item.eventDate.updated).toBe(false);
    });

    it('toggles number on when date toggled on', function() {

        var item = buildItem();

        item.number.updated = false;
        item.eventDate.updated = true;

        item.id = null;

        fixture.controller();
        fixture.scope.toggleDateSelection(item);
        expect(item.number.updated).toBe(true);
        expect(item.eventDate.updated).toBe(true);
    });

    it('toggles number separately for existing numbers', function() {

        var item = buildItem();

        item.number.updated = false;
        item.eventDate.updated = true;

        fixture.controller();
        fixture.scope.toggleNumberSelection(item);
        expect(item.number.updated).toBe(false);
        expect(item.eventDate.updated).toBe(true);
    });

    it('toggles date separately for existing numbers', function() {

        var item = buildItem();

        item.number.updated = false;
        item.eventDate.updated = true;

        fixture.controller();
        fixture.scope.toggleDateSelection(item);
        expect(item.number.updated).toBe(false);
        expect(item.eventDate.updated).toBe(true);
    });
});
