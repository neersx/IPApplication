import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy } from '@angular/core';
import { BehaviorSubject, of, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, map, switchMap, tap } from 'rxjs/operators';
import { CaseSearchService } from 'search/case/case-search.service';
import { findWhere } from 'underscore';
import { CaseSearchSummaryModel } from './search-summary.model';

@Component({
  selector: 'ipx-case-search-summary',
  templateUrl: 'case-search-summary.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxCaseSearchSummaryComponent implements AfterViewInit, OnDestroy {
  @Input() set caseKey(key: number) {
    this.caseKey$.next(key);
  }
  @Input() hasOffices: Boolean;
  @Input() hasFileLocation: Boolean;
  @Input() showLink: Boolean;
  @Input() isExternal: Boolean;
  @Input() rowKey: string;
  @Input() programId: string;

  caseSearchSummary: CaseSearchSummaryModel;
  subscription: Subscription;
  showImage: Boolean = false;
  caseKey$ = new BehaviorSubject<number>(null);

  constructor(private readonly caseSearchService: CaseSearchService, private readonly cdRef: ChangeDetectorRef) {
  }

  ngAfterViewInit(): void {
    this.subscription = this.caseKey$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      switchMap(selectedCaseKey => {
        if (selectedCaseKey) {
          return this.caseSearchService.getCaseSummary(selectedCaseKey);
        }
        this.caseSearchSummary = null;

        return of(null);
      })
    ).subscribe((summary: any) => {
      this.cdRef.markForCheck();
      if (summary === null) {
        this.caseSearchSummary = null;

        return;
      }

      this.caseSearchSummary = new CaseSearchSummaryModel();
      this.caseSearchSummary.showImage = false;
      this.caseSearchSummary.caseData = summary.caseData;
      this.caseSearchSummary.names = summary.names;
      this.caseSearchSummary.criticalDates =
        summary.dates.filter((e: { isNextDueEvent: any; isLastEvent: any; }) => !e.isNextDueEvent && !e.isLastEvent);
      this.caseSearchSummary.nextDueEvent = findWhere(summary.dates, { isNextDueEvent: true });
      this.caseSearchSummary.lastEvent = findWhere(summary.dates, { isLastEvent: true });
      if (summary.caseData.imageKey) {
        setTimeout(() => {
          this.cdRef.markForCheck();
          this.caseSearchSummary.showImage = true;
        });
      }
    });
  }

  encodeLinkData = (data: any) => {
    return 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({ nameKey: data }));
  };

  trackByFn = (index, item) => {
    return item;
  };

  ngOnDestroy(): void {
    if (!!this.subscription) {
      this.subscription.unsubscribe();
    }
  }
}
