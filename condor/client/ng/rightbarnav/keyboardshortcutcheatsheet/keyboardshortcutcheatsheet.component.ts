import { ChangeDetectionStrategy, ChangeDetectorRef, Component } from '@angular/core';
import { Hotkeys } from 'ajs-upgraded-providers/hotkeys.provider';
import * as angular from 'angular';
import { Hotkey, HotkeysService } from 'angular2-hotkeys';
import { BsModalRef } from 'ngx-bootstrap/modal';
import * as _ from 'underscore';

@Component({
  selector: 'app-keyboardshortcutcheatsheet',
  templateUrl: './keyboardshortcutcheatsheet.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class KeyboardShortcutCheatSheetComponent {
  hotkeysList: Array<Hotkey> = [];
  modalRef: BsModalRef;

  constructor(private readonly cdref: ChangeDetectorRef,
    private readonly bsModalRef: BsModalRef,
    private readonly hotkeysService: HotkeysService, private readonly hotKeys: Hotkeys) {
    this.hotkeysList = angular.extend(this.hotkeysService.hotkeys, hotKeys.get().slice());
    this.modalRef = bsModalRef;
  }

  close(): void {
    this.modalRef.hide();
  }

  format = (hotkey: any) => {
    let all = [];
    all = angular.isFunction(hotkey.format) ? hotkey.format() : hotkey.formatted;

    return _.flatten(_.map(all, (item) => {
      return item.replace('\u21E7', 'shift').split([' + ']);
    }));
  };

  trackByFn = (index: number, item: any) => {
    return index;
  };
}
