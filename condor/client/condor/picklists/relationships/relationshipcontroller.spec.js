describe('inprotech.picklists.relationshipController', function() {
    'use strict';

    var controller, scope;

    beforeEach(module('inprotech.picklists'));
    beforeEach(module('inprotech.components.picklist'));

    beforeEach(inject(function($rootScope, $controller) {
        scope = $rootScope.$new();
        scope.vm = {};

        controller = function() {
            var dependencies = {
                $scope: scope
            };

            return $controller('relationshipController', dependencies);
        };
    }));

    it('should default toEvent', function() {
        var c = controller();
        var src = 'fromEvent';
        var entry = {
            fromEvent: {
                key: '-1',
                value: 'Official Action 12 month Deadline'
            }
        };
        var maintenance = {
            fromEvent: {},
            toEvent: {}
        };

        c.onEventChange(entry, src, maintenance);

        expect(entry.toEvent).toEqual(entry.fromEvent);
    });
    it('should not default toEvent if it is already entered', function() {
        var c = controller();
        var src = 'fromEvent';
        var entry = {
            toEvent: {
                key: '-1',
                value: 'Official Action 12 month Deadline'
            }
        };
        var maintenance = {
            fromEvent: {},
            toEvent: {}
        };

        entry.fromEvent = {
            key: '-2',
            value: 'Translation Deadline (incl 10 days)'
        };

        c.onEventChange(entry, src, maintenance);

        expect(entry.toEvent).toEqual(entry.toEvent);
    });
    it('should initailise show flag', function() {
        var ctr = controller();
        var modal = {
            maintenanceState: 'adding',
            entry: {}
        };
        ctr.init(modal);
        expect(modal.entry.showFlag).toEqual(1);
    });
    it('should initailise show flag', function() {
        var ctr = controller();
        var modal = {
            maintenanceState: 'updating',
            entry: {
                showFlag: 0
            }
        };
        ctr.init(modal);
        expect(modal.entry.showFlag).not.toEqual(1);
    });
});
