import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { exchangeRateSchedule } from './exchange-rate-schedule-states';
import { ExchangeRateScheduleComponent } from './exchange-rate-schedule.component';
import { ExchangeRateScheduleService } from './exchange-rate-schedule.service';
import { MaintainExchangeRateScheduleComponent } from './maintain-exchange-rate-schedule/maintain-exchange-rate-schedule.component';
@NgModule({
    declarations: [
        ExchangeRateScheduleComponent,
        MaintainExchangeRateScheduleComponent
    ],
    imports: [
        SharedModule,
        ButtonsModule,
        UIRouterModule.forChild({ states: [exchangeRateSchedule] })
    ],
    providers: [
        ExchangeRateScheduleService
    ],
    exports: [
    ],
    entryComponents: [MaintainExchangeRateScheduleComponent]
})
export class ExchangeRateScheduleModule { }