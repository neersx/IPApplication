import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { Observable, of } from 'rxjs';
import { AccountingService } from '../accounting.service';

@Component({
    selector: 'ipx-name-financial',
    templateUrl: './name-financial.component.html',
    styleUrls: ['./name-financial.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class NameFinancialComponent implements OnInit {
    @Input() nameKey: number;
    currencyCode: string;
    nameBalances$: Observable<any>;
    canViewReceivables: boolean;
    showAgedBalance: boolean;
    constructor(
        private readonly accountingService: AccountingService
    ) { }

    ngOnInit(): void {
        this.currencyCode = this.accountingService.getCurrencyCode();
        this.canViewReceivables = this.accountingService.getViewReceivablesPermission();
        this.loadData();
    }

    loadData = () => {
        if (this.nameKey && !this.nameBalances$) {
            this.nameBalances$ = this.accountingService
                .getReceivableBalance(this.nameKey, true);
        } else {
            this.nameBalances$ = of(undefined);
        }
    };
}
