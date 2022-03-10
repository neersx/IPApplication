// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration } from '@uirouter/angular';
import { ExchangeRateScheduleComponent } from './exchange-rate-schedule.component';
import { ExchangeRateSchedulePermissions } from './exchange-rate-schedule.model';
import { ExchangeRateScheduleService } from './exchange-rate-schedule.service';

export function getViewData(service: ExchangeRateScheduleService): Promise<ExchangeRateSchedulePermissions> {
    return service.getViewData().toPromise();
}

export const exchangeRateSchedule: Ng2StateDeclaration = {
    name: 'exchangerateschedule',
    url: '/configuration/exchange-rate-schedule',
    component: ExchangeRateScheduleComponent,
    data: {
        pageTitle: 'exchangeRateSchedule.maintenance.title'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [ExchangeRateScheduleService],
                resolveFn: getViewData
            }
        ]
};