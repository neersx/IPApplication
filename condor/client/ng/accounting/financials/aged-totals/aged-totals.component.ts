import { ChangeDetectionStrategy, Component, Input, OnChanges, OnInit, SimpleChanges } from '@angular/core';
import { Observable, of } from 'rxjs';
import { AccountingService } from '../accounting.service';
import { AgedTotalsService } from './aged-totals.service';

@Component({
    selector: 'ipx-aged-totals',
    templateUrl: './aged-totals.component.html',
    styleUrls: ['./aged-totals.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class AgedTotalsComponent implements OnInit, OnChanges {
    @Input() caseKey: number;
    @Input() nameKey: number;

    currencyCode: string;
    agedTotals$: Observable<any>;

    constructor(
        private readonly service: AgedTotalsService,
        private readonly accounting: AccountingService
    ) { }

    ngOnInit(): void {
        this.loadData();
        this.currencyCode = this.accounting.getCurrencyCode();
    }

    loadData = () => {
        if (!this.caseKey && !this.nameKey) {
            this.agedTotals$ = of(undefined);

            return;
        }
        if (this.caseKey) {
            this.agedTotals$ = this.service.getWipData(this.caseKey);
        } else if (this.nameKey) {
            this.agedTotals$ = this.service.getAgedReceivables(this.nameKey);
        }
    };

    byEntity = (index: number, item: any): number => item.id;

    ngOnChanges(changes: SimpleChanges): void {
        if (changes.caseKey) {
            this.caseKey = changes.caseKey.currentValue;
            this.loadData();
        }
    }
}
