import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy } from '@angular/core';
import { Observable, of, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, map, switchMap, tap } from 'rxjs/operators';
import * as _ from 'underscore';
import { TimeRecordingService } from '../time-recording-service';
import { CaseSummaryModel } from './case-summary.model';
import { CaseSummaryService } from './case-summary.service';

@Component({
    selector: 'ipx-case-summary-details',
    templateUrl: './case-summary-details.component.html',
    styleUrls: ['./case-summary-details.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseSummaryDetailsComponent implements AfterViewInit, OnDestroy {
    // tslint:disable-next-line: prefer-inline-decorator
    @Input()
    set caseKey(caseKey: number) {
        this._caseKey = caseKey;
    }
    get caseKey(): number {
        return this._caseKey;
    }

    @Input() showLink: any;
    @Input() isDisplayed: any;

    caseRef: string;
    loadDataDebounce: Function;
    caseSummary: CaseSummaryModel;
    subscription: Subscription;
    instructorNameType: string;
    private _caseKey;

    constructor(
        private readonly caseSummaryService: CaseSummaryService,
        private readonly timeService: TimeRecordingService,
        private readonly cdref: ChangeDetectorRef
    ) { }

    ngAfterViewInit(): void {
        this.subscription = this.timeService.rowSelected.pipe(
            debounceTime(300),
            distinctUntilChanged(),
            tap((selectedCaseKey) => {
                this.caseKey = selectedCaseKey;
            }),
            switchMap(selectedCaseKey => {
                if (selectedCaseKey) {
                    return this.caseSummaryService.getCaseSummary(selectedCaseKey);
                }

                return of(null);
            })
        ).subscribe((summary: any) => {
            this.cdref.markForCheck();
            this.caseSummary = summary ? summary as CaseSummaryModel : null;
            this.instructorNameType = summary && summary.instructor ? summary.instructor.type : '';
        });
    }

    encodeLinkData = (data: any) =>
        'api/search/redirect?linkData=' +
        encodeURIComponent(JSON.stringify({ nameKey: data }));

    byEntity = (index: number, item: any): number => item.id;

    ngOnDestroy(): void {
        if (!!this.subscription) {
            this.subscription.unsubscribe();
        }
    }
}
