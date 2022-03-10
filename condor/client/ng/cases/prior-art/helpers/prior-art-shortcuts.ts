import { Injectable } from '@angular/core';
import { Hotkey, HotkeysService } from 'angular2-hotkeys';

@Injectable()
export class PriorArtShortcuts {
    listOfShortcuts: Array<Hotkey> = [];
    constructor(
        private readonly hotkeysService: HotkeysService
    ) { }

    registerHotkeysForSave(): void {
        const combo = 'alt+shift+s';
        const saveShortcut = this.hotkeysService.add(new Hotkey(combo, () => {

            return null;
        }, undefined, 'shortcuts.save'));
        this.listOfShortcuts.push(saveShortcut as Hotkey);
    }

    registerHotkeysForRevert(): void {
        const combo = 'alt+shift+z';
        const revertShortcut = this.hotkeysService.add(new Hotkey(combo, () => {

            return null;
        }, undefined, 'shortcuts.revert'));
        this.listOfShortcuts.push(revertShortcut as Hotkey);
    }

    registerHotkeysForSearch(): void {
        const combo = 'enter';
        const revertShortcut = this.hotkeysService.add(new Hotkey(combo, () => {

            return null;
        }, undefined, 'shortcuts.search'));
        this.listOfShortcuts.push(revertShortcut as Hotkey);
    }

    flushShortcuts(): void {
        if (this.listOfShortcuts.length) {
            this.hotkeysService.remove(this.listOfShortcuts);
        }
    }
}