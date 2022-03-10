// tslint:disable:only-arrow-functions
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { LocalSettings } from 'core/local-settings';
import { TaxCodeComponent } from './tax-code-component';
import { TaxCodeDetailsComponent } from './tax-code-details.component';
import { TaxCodeService } from './tax-code.service';

export function getTaxCodeViewData(_service: TaxCodeService): Promise<any> {
    return _service.getTaxCodeViewData().toPromise();
}

export function runSearch(service: TaxCodeService, localSettings: LocalSettings, transition: Transition): Promise<any> {
    const fromParams = transition.params('from');
    if (fromParams && !fromParams.id && transition.from().name !== 'taxcodes') {
        return service.getTaxCodes(localSettings.keys.navigation.searchCriteria.getLocal, localSettings.keys.navigation.queryParams.getLocal).toPromise();
    }
}

export const taxCodeState: Ng2StateDeclaration = {
    name: 'taxcodes',
    url: '/configuration/taxcodes',
    params: {},
    component: TaxCodeComponent,
    data: {
        pageTitle: 'taxCode.pageTitle'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [TaxCodeService],
                resolveFn: getTaxCodeViewData
            }
        ]
};

export const taxCodeDetailState: Ng2StateDeclaration = {
    name: 'tax-details',
    url: '/configuration/taxcodes/?:id',
    params: {
        id: {
            type: 'int'
        },
        rowKey: undefined
    },
    component: TaxCodeDetailsComponent,
    data: {
        pageTitle: 'taxCode.detailPage'
    },
    resolve:
        [
            {
                token: 'stateParams',
                deps: [Transition],
                resolveFn: getStateParameters
            },
            {
                token: 'viewData',
                deps: [TaxCodeService],
                resolveFn: getTaxCodeViewData
            },
            {
                token: 'search',
                deps: [TaxCodeService, LocalSettings, Transition],
                resolveFn: runSearch
            }
        ]
};

export function getStateParameters($transition: Transition): any {
    return {
        id: $transition.params().id,
        rowKey: $transition.params().rowKey
    };
}