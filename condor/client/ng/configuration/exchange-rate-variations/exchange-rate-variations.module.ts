import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { exchangeRateVariations } from './exchange-rate-variations-states';
import { ExchangeRateVariationComponent } from './exchange-rate-variations.component';
import { ExchangeRateVariationService } from './exchange-rate-variations.service';
import { MaintainExchangerateVarComponent } from './maintain-exchangerate-var/maintain-exchangerate-var.component';
@NgModule({
    declarations: [
        ExchangeRateVariationComponent,
        MaintainExchangerateVarComponent
    ],
    imports: [
        SharedModule,
        ButtonsModule,
        UIRouterModule.forChild({ states: [exchangeRateVariations] })
    ],
    providers: [
        ExchangeRateVariationService
    ],
    exports: [
    ]
})
export class ExchangeRateVariationModule { }