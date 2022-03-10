import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { LocalCurrencyFormatPipe } from 'shared/pipes/local-currency-format.pipe';
import { SharedModule } from './../../shared/shared.module';
import { AccountingService } from './accounting.service';
import { AgedTotalsComponent } from './aged-totals/aged-totals.component';
import { AgedTotalsService } from './aged-totals/aged-totals.service';
import { CaseFinancialComponent } from './case-financial/case-financial.component';
import { NameFinancialComponent } from './name-financial/name-financial.component';

@NgModule({
    declarations: [
        NameFinancialComponent,
        CaseFinancialComponent,
        AgedTotalsComponent
    ],
    imports: [CommonModule, SharedModule],
    exports: [NameFinancialComponent, CaseFinancialComponent, LocalCurrencyFormatPipe],
    providers: [AgedTotalsService, AccountingService]
})
export class FinancialsModule {}
