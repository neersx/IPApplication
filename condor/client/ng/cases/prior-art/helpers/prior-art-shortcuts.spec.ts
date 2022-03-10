import { HotKeysMock } from 'mocks';
import { PriorArtShortcuts } from './prior-art-shortcuts';

describe('Service: PriorArtShortcuts', () => {
    let service: PriorArtShortcuts;
    let hotKeys: HotKeysMock;

    beforeEach(() => {
        hotKeys = new HotKeysMock();
        service = new PriorArtShortcuts(hotKeys as any);
    });
    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });
    describe('registering and clearing hot keys', () => {
        beforeEach(() => {
            service.registerHotkeysForRevert();
            service.registerHotkeysForSave();
            service.registerHotkeysForSearch();
        });
        it('should register hot keys', () => {
            expect(hotKeys.addedKeys).toEqual(
                expect.arrayContaining([
                    expect.objectContaining({ combo: ['alt+shift+s'], description: 'shortcuts.save' }),
                    expect.objectContaining({ combo: ['alt+shift+z'], description: 'shortcuts.revert' }),
                    expect.objectContaining({ combo: ['enter'], description: 'shortcuts.search' })
                ]));
            expect(service.listOfShortcuts).toEqual(
                expect.arrayContaining([
                    expect.objectContaining({ combo: ['alt+shift+s'], description: 'shortcuts.save' }),
                    expect.objectContaining({ combo: ['alt+shift+z'], description: 'shortcuts.revert' }),
                    expect.objectContaining({ combo: ['enter'], description: 'shortcuts.search' })
                ]));
        });
        it('should clear all shortcuts', () => {
            service.flushShortcuts();
            expect(hotKeys.remove.mock.calls[0][0]).toEqual(expect.arrayContaining([
                expect.objectContaining({ combo: ['alt+shift+s'], description: 'shortcuts.save' }),
                expect.objectContaining({ combo: ['alt+shift+z'], description: 'shortcuts.revert' }),
                expect.objectContaining({ combo: ['enter'], description: 'shortcuts.search' })
            ]));
        });
    });
});