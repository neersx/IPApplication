import { Injectable } from '@angular/core';
import { Hotkey, HotkeysService } from 'angular2-hotkeys';

@Injectable()
export class KeyBoardShortCutInitializerService {
    stack = [];
    isPop: boolean;
    constructor(private readonly hotKeysService: HotkeysService) {
        this.isPop = false;
    }

    init(): Promise<void> {
        return new Promise<void>((resolve) => {
            // tslint:disable-next-line: no-unbound-method
            const oldAdd = this.hotKeysService.add;
            this.hotKeysService.add = (hotkey: Hotkey, specificEvent?: string) => {

                if (hotkey.allowIn == null || hotkey.allowIn.length === 0) {
                    hotkey.allowIn = ['INPUT', 'SELECT', 'TEXTAREA'];
                }

                // hotkey.description = this.translate.instant(hotkey.description);
                hotkey.description = hotkey.description;
                const oldCallback = hotkey.callback;

                hotkey.callback = (event: KeyboardEvent, combo: string): any => {
                    if (!oldCallback.apply(null, [event, combo])) {
                        event.preventDefault();
                    }
                };

                return oldAdd.apply(this.hotKeysService, [hotkey, specificEvent]);
            };
            resolve();
        });
    }
}