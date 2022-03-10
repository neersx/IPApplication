import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { AppContextService } from 'core/app-context.service';
import { take } from 'rxjs/operators';
import { LocalCache } from '../../core/local-cache';
import { LocalSettings } from '../../core/local-settings';
import { Storage } from '../../core/storage';

@Component({
  selector: 'ngx-storage',
  templateUrl: './storage-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class StorageComponent implements OnInit {
  showPreview: boolean;
  showPreviewLocal: boolean;
  caseViewActionPageNumberLocal: number;
  caseViewActionPageNumberCache: number;

  constructor(private readonly store: Storage, private readonly appContextService: AppContextService,
    private readonly localSettings: LocalSettings,
    private readonly cache: LocalCache) { }

  ngOnInit(): void {
    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe(() => {
        this.showPreview = this.store.local.get('showPreview') === true ? true : false;
        this.showPreviewLocal = this.store.local.get('showPreviewLocal') === true ? true : false;

        this.caseViewActionPageNumberLocal = this.localSettings.keys.caseView.actions.pageNumber.getLocal;
        this.caseViewActionPageNumberCache = this.cache.keys.caseView.actions.pageNumber.get;
      }
      );
  }

  changeShowPreviewLocal = () => {
    this.showPreviewLocal = !this.showPreviewLocal;
    this.store.local.set('showPreviewLocal', this.showPreviewLocal);
  };
}
