import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { StateService } from '@uirouter/core';
import { AppContextService } from 'core/app-context.service';
import { Subject } from 'rxjs';
import { take } from 'rxjs/operators';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import * as _ from 'underscore';
import { QuickSearchService } from './quick-search.service';

@Component({
  selector: 'ipx-quick-search',
  templateUrl: './quick-search.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class QuickSearchComponent implements OnInit {
  textfield = new Subject<string>();
  text: string;
  items: Array<ListItem>;
  enterPressed: Boolean = false;
  subscriberService: any;
  canAccessQuickSearch = false;
  isExternal = false;

  constructor(
    private readonly service: QuickSearchService,
    private readonly $state: StateService,
    private readonly cdRef: ChangeDetectorRef,
    private readonly appContextService: AppContextService
  ) { }

  checkAccessLevels = (): boolean => {

    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe((ctx: any) => {
        this.canAccessQuickSearch = ctx.user.permissions.canAccessQuickSearch;
        this.isExternal = ctx.user.isExternal;
      });

    return this.canAccessQuickSearch;
  };

  ngOnInit(): void {
    if (!this.checkAccessLevels()) {
      return;
    }
    this.textfield.subscribe(text => {
      if (this.subscriberService) {
        this.subscriberService.unsubscribe();
      }
      this.text = text;
      if (this.text) {
        this.doSearch();
      } else {
        this.items = null;
      }
    });
  }

  onMouseOver = (item: ListItem) => {
    _.forEach(this.items, (i: ListItem) => {
      i.$highlighted = false;
    });

    item.$highlighted = true;
  };

  onSelect = (item: any, $event): void => {
    if (!$event || $event.button === 1 || $event.which === 1) {
      this.text = item.irn;
      this.items = null;
      this.cdRef.markForCheck();
      const options =
        this.$state.current.name === 'caseview' ? { location: 'replace' } : null;
      this.$state.go(
        'caseview',
        {
          id: item.id,
          canLevelUp: false
        },
        options
      );
    }
  };

  onBlur(): void {
    this.items = null;
  }

  onCaseSearch = () => {
    const options =
      this.$state.current.name === 'search-results'
        ? { location: 'replace' }
        : null;
    const searchTerm = this.text ? this.text.trim() : '';
    this.items = null;
    this.cdRef.markForCheck();
    this.$state.go(
      'search-results',
      {
        q: searchTerm,
        filter: null,
        queryKey: null,
        rowKey: null,
        searchQueryKey: false,
        queryContext: this.isExternal ? queryContextKeyEnum.caseSearchExternal as number : queryContextKeyEnum.caseSearch as number
      },
      options
    );
  };

  onKeydown = $event => {
    const idx = _.findIndex(this.items, { $highlighted: true });
    this.enterPressed = false;
    // tslint:disable-next-line: switch-default
    switch ($event.keyCode) {
      case 13: // enter
        if (this.items && idx >= 0) {
          this.onSelect(this.items[idx], null);
        } else {
          this.enterPressed = true;
          this.service.get(this.text).subscribe(response => {
            this.items = response;
            // Go direct on single result
            if (this.items && this.items.length === 1) {
              this.onSelect(this.items[0], null);
            } else {
              this.onCaseSearch();
            }
          });
        }
        break;
      case 40: // down arrow
        if (this.items.length > 0) {
          if (idx >= 0 && idx < this.items.length - 1) {
            this.items[idx].$highlighted = false;
            this.items[idx + 1].$highlighted = true;
          } else {
            // rotation
            if (idx === this.items.length - 1) {
              this.items[idx].$highlighted = false;
            }
            this.items[0].$highlighted = true;
          }
        } else if (this.text) {
          this.doSearch(true);
        }
        break;
      case 38: // up arrow
        if (this.items.length > 0 && idx > 0) {
          this.items[idx].$highlighted = false;
          this.items[idx - 1].$highlighted = true;
        }
        break;
      case 9: // Tab
        if (this.items && idx > -1) {
          this.text = this.items[idx].irn;
          $event.preventDefault();
          this.items = null;
        }
        break;
      case 27: // esc
        this.items = null;
        break;
    }
  };

  doSearch = (setFocus = false) => {
    if (!this.enterPressed) {
      this.subscriberService = this.service
        .get(this.text)
        .subscribe(response => {
          this.items = response;
          if (setFocus) {
            if (this.items && this.items.length) {
              this.items[0].$highlighted = true;
            }
          }
          this.cdRef.markForCheck();
        });
    }
    this.enterPressed = false;
  };
}
export class ListItem {
  id: number;
  irn: string;
  matchedOn?: string;
  sortOrder?: number;
  using?: number;
  previousState?: string;
  $highlighted?: boolean;
}
