describe('inprotech.core.hotkeyService', function() {
    'use strict';

    var service, hotkeys, transitions;

    beforeEach(module('inprotech.core'));
    beforeEach(module(function() {
        hotkeys = test.mock('hotkeys');
        transitions = test.mock('$transitions', 'transitionsMock');
    }));

    beforeEach(inject(function(hotkeyService) {
        service = hotkeyService;
    }));

    it('should wire up reset for page success transition', function() {
        expect(transitions.onSuccess).toHaveBeenCalledWith(jasmine.any(Object), service.reset);
    });

    it('should reset hotkey backups', function() {
        service.reset();
        expect(hotkeys.purgeHotkeys).toHaveBeenCalled();
        expect(service.get()).toEqual([]);
    });

    it('should clone current hotkeys', function() {
        hotkeys.get = function() {
            return [{
                combo: ['a'],
                description: 'b',
                allowIn: 'c',
                callback: 'd'
            }];
        };

        var items = service.clone();
        expect(items).toEqual([{
            combo: 'a',
            description: 'b',
            allowIn: 'c',
            callback: 'd'
        }])
    });

    it('should add hotkeys', function() {
        hotkeys.add = jasmine.createSpy();
        service.add(['a']);        
        expect(hotkeys.add).toHaveBeenCalledWith('a');
    });

    it('should backup hotkeys', function() {
        service.clone = function() {
            return 'a';
        };

        service.push();
        expect(service.get()).toEqual(['a']);
        expect(hotkeys.purgeHotkeys).toHaveBeenCalled();
    });

    it('should restore hotkeys', function() {
        service.add = jasmine.createSpy();
        service.get().push('a');
        hotkeys.clone = function() {
            return 'a';
        };

        service.pop();

        expect(hotkeys.purgeHotkeys).toHaveBeenCalled();
        expect(service.add).toHaveBeenCalledWith('a');
    });
});
