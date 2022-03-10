import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { StateService } from '@uirouter/angular';
import { Hotkey, HotkeysService } from 'angular2-hotkeys';
import { LastSearchService } from '../../shared/component/page/last-search.service';

@Component({
  selector: 'page-test',
  templateUrl: './page.dev.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class PageTitleTestComponent implements OnInit {
  btnName: string;
  id: any;
  lastSearch: LastSearchService;

  constructor(public $state: StateService, private readonly lastSearchService: LastSearchService, public hotKeysService: HotkeysService) {
    this.id = this.$state.params.id;

    this.lastSearchService.setInitialData({
      method: () => new Promise<any>((resolve) => { resolve([1, 2, 3, 4, 5]); }),
      args: []
    });
    this.lastSearch = this.lastSearchService;
  }

  ngOnInit(): void {

    const hotkeys = [
      new Hotkey(
        'alt+shift+s',
        (event, combo): boolean => {
          if (this.isSaveEnabled()) {
            this.save();
          }

          return false;
        }, undefined, 'shortcuts.save'),
      new Hotkey(
        'alt+shift+z',
        (event, combo): boolean => {
          if (this.isDiscardEnabled()) {
            this.discard();
          }

          return false;
        }, undefined, 'shortcuts.revert')
    ];
    this.hotKeysService.add(hotkeys);
  }

  save = (): void => { this.btnName = 'Save'; };

  discard = (): void => { this.btnName = 'Revert'; };

  isSaveEnabled = (): boolean => true;

  isDiscardEnabled = (): boolean => true;
}
