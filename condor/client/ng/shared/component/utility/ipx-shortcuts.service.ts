import { Injectable } from '@angular/core';
import { Hotkey, HotkeysService } from 'angular2-hotkeys';
import { RegisterableShortcuts, SHORTCUTSMETADATA } from 'core/registerable-shortcuts.enum';
import { Observable, Observer } from 'rxjs';
import { filter, share } from 'rxjs/operators';
import * as _ from 'underscore';

@Injectable({
  providedIn: 'root'
})
export class IpxShortcutsService {
  private readonly shortcutFired$: Observable<any>;
  private observer: Observer<any>;

  constructor(private readonly hotkeysService: HotkeysService) {
    this.shortcutFired$ = new Observable((observer: Observer<any>) => {
      this.observer = observer;
    }).pipe(share());
  }

  private readonly getMetaData = (key: RegisterableShortcuts, checkPresence: boolean): any => {
    if (!SHORTCUTSMETADATA.has(key)) {
      return null;
    }

    const data = SHORTCUTSMETADATA.get(key);
    if (checkPresence && _.any(this.hotkeysService.hotkeys, (h: Hotkey) => { return h.combo[0] === data.combo; })) {
      return null;
    }

    return data;
  };

  private readonly register = (key: RegisterableShortcuts): void => {
    const data = this.getMetaData(key, true);
    if (!data) {
      return;
    }

    this.hotkeysService.add(new Hotkey(data.combo, (): boolean => {
      if (this.observer != null) {
        this.observer.next(key);
      }

      return false;
    }, undefined, data.description));
  };

  observeMultiple$ = (keys: Array<RegisterableShortcuts>): Observable<any> => {
    _.each(keys, (k) => {
      this.register(k);
    });

    return this.shortcutFired$;
  };
}