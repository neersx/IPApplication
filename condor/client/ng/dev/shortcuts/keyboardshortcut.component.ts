import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { ModalService } from 'ajs-upgraded-providers/modal-service.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Hotkey, HotkeysService } from 'angular2-hotkeys';

@Component({
    selector: 'ngx-hotkeys',
    templateUrl: './keyboardshortcut.components.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class KeyboardShortCutExampleComponent implements OnInit {
    listOfShortcuts: Array<string> = [];
    shortcut: string;
    constructor(public notificationService: NotificationService,
        private readonly hotkeysService: HotkeysService,
        public modalService: ModalService) { }

    ngOnInit(): void {

        this.hotkeysService.add(new Hotkey('h', (): boolean => {
            this.displayCheatSheet();

            return false;
        }, undefined, 'Display shortcuts'));
    }

    addShortcut = () => {
        if (!this.shortcut) {
            return;
        }

        const combo = this.shortcut.toLowerCase();
        this.listOfShortcuts.push(combo);

        this.hotkeysService.add(new Hotkey(combo, (): boolean => {
            this.notificationService.success(combo + ' works here!');

            return false;
        }, undefined, combo));

    };

    displayCheatSheet = () => {
        this.modalService.open('cheatsheet');
    };

    byItem = (index: number, item: any): string => item;
}
