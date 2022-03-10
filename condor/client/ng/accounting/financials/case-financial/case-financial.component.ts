import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { of, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap, tap } from 'rxjs/operators';
import * as _ from 'underscore';
import { CaseSummaryService } from '../../time-recording/case-summary-details/case-summary.service';
import { TimeRecordingService } from '../../time-recording/time-recording-service';
import { AccountingService } from '../accounting.service';

@Component({
    selector: 'ipx-case-financial',
    templateUrl: './case-financial.component.html',
    styleUrls: ['./case-financial.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseFinancialComponent implements OnInit, OnDestroy {
    @Input() set caseKey(value: number) {
        this._caseKey = value;
    }
    get caseKey(): number {
        return this._caseKey;
    }

    caseFinancials: any;
    currencyCode: string;
    subscription: Subscription;
    canViewWip: boolean;
    hasWipBalance: boolean;
    private _caseKey: number;
    private _canViewWip: boolean;

    constructor(
        private readonly caseSummaryService: CaseSummaryService,
        private readonly timeService: TimeRecordingService,
        private readonly accountingService: AccountingService,
        private readonly cdref: ChangeDetectorRef
    ) { }

    ngOnInit(): void {
        this.currencyCode = this.accountingService.getCurrencyCode();
        this._canViewWip = this.accountingService.getViewWipPermission();

        this.subscription = this.timeService.rowSelected.pipe(
            debounceTime(300),
            distinctUntilChanged(),
            tap(selectedCaseKey => this.caseKey = selectedCaseKey),
            switchMap(selectedCaseKey => {
                if (selectedCaseKey) {
                    return this.caseSummaryService.getCaseFinancials(selectedCaseKey);
                }

                return of(null);
            })
        ).subscribe((summary: any) => {
            this.caseFinancials = summary ? summary : undefined;
            this.hasWipBalance = this.caseFinancials && this.caseFinancials.wip !== 0;
            this.canViewWip = this._canViewWip;
            this.cdref.detectChanges();
        });
    }

    ngOnDestroy(): void {
        if (!!this.subscription) {
            this.subscription.unsubscribe();
        }
    }
}
