// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { ExchangeRateVariationComponent } from './exchange-rate-variations.component';
import { ExchangeRateVariationPermissions } from './exchange-rate-variations.model';
import { ExchangeRateVariationService } from './exchange-rate-variations.service';

export function getViewData(service: ExchangeRateVariationService, $transition): Promise<ExchangeRateVariationPermissions> {
    return service.getViewData($transition.params().exchangeRateSchedule).toPromise();
}

export const exchangeRateVariations: Ng2StateDeclaration = {
    name: 'exchange-rate-variation',
    url: '/configuration/exchange-rate-variation',
    component: ExchangeRateVariationComponent,
    params: {
        currency: null,
        exchangeRateSchedule: null
    },
    data: {
        pageTitle: 'exchangeRateVariation.maintenance.title'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [ExchangeRateVariationService, Transition],
                resolveFn: getViewData
            }
        ]
};