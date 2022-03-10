import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ExchangeRateVariationModule } from 'configuration/exchange-rate-variations/exchange-rate-variations.module';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { currencies } from './currencies-states';
import { CurrenciesComponent } from './currencies.component';
import { CurrenciesService } from './currencies.service';
import { ExchangeRateHistoryComponent } from './exchange-rate-history/exchange-rate-history.component';
import { MaintainCurrenciesComponent } from './maintain-currencies/maintain-currencies.component';
@NgModule({
    declarations: [
        CurrenciesComponent,
        ExchangeRateHistoryComponent,
        MaintainCurrenciesComponent
    ],
    imports: [
        SharedModule,
        ButtonsModule,
        ExchangeRateVariationModule,
        UIRouterModule.forChild({ states: [currencies] })
    ],
    providers: [
        CurrenciesService
    ],
    exports: [
    ],
    entryComponents: [MaintainCurrenciesComponent]
})
export class CurrenciesModule { }