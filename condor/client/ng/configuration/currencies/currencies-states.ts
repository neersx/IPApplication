// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration } from '@uirouter/angular';
import { CurrenciesComponent } from './currencies.component';
import { CurrencyPermissions } from './currencies.model';
import { CurrenciesService } from './currencies.service';

export function getViewData(service: CurrenciesService): Promise<CurrencyPermissions> {
    return service.getViewData().toPromise();
}

export const currencies: Ng2StateDeclaration = {
    name: 'currencies',
    url: '/configuration/currencies',
    component: CurrenciesComponent,
    data: {
        pageTitle: 'currencies.maintenance.title'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [CurrenciesService],
                resolveFn: getViewData
            }
        ]
};