import { Injectable } from '@angular/core';
import { TransitionService } from '@uirouter/core';
import { Hotkey, HotkeysService } from 'angular2-hotkeys';
import * as _ from 'underscore';

@Injectable()
export class KeyBoardShortCutService {
    stack = [];
    isPop: boolean;
    constructor(private readonly hotKeysService: HotkeysService, private readonly transitionService: TransitionService) {
        this.isPop = false;
        this.transitionService.onSuccess({}, this.reset);
    }

    purgeHotkeys = () => {
        let i = this.hotKeysService.hotkeys.length;
        while (i--) {
            const hotkey = this.hotKeysService.hotkeys[i];
            if (hotkey && !hotkey.persistent) {
                this.hotKeysService.remove(hotkey);
            }
        }
    };

    reset = () => {
        this.stack = [];
        this.purgeHotkeys();
    };

    push = () => {
        const cloneKey = this.clone();
        if (cloneKey.length > 0) {
            cloneKey.forEach(element => {
                this.stack.push(element);
            });
        }
        this.purgeHotkeys();
    };

    pop = () => {
        this.isPop = true;
        if (this.stack.length > 0) {
            this.purgeHotkeys();
        }
        this.add(this.stack);
        this.isPop = false;
        this.stack = [];
    };

    clone = () => {
        const items = this.hotKeysService.hotkeys.filter(x => !x.persistent);

        return items;
    };

    add = (items: any) => {
        if (items) {
            const list = Array.isArray(items) ? items : [items];
            list.forEach((a: Hotkey) => {
                this.hotKeysService.add(a);
            });
        }
    };

    get = () => {
        return this.stack;
    };
}