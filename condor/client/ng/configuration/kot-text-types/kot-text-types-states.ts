// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { KotTextTypesComponent } from './kot-text-types.component';
import { KotTextTypesService } from './kot-text-types.service';

export function getKotPermissions(service: KotTextTypesService): Promise<any> {
    return service.getKotPermissions().toPromise();
}

export const kotTextTypesCase: Ng2StateDeclaration = {
    name: 'kotTextTypesCase',
    url: '/configuration/kottexttypes/case',
    component: KotTextTypesComponent,
    params: {
        isCaseType: true
    },
    data: {
        pageTitle: 'kotTextTypes.configuration'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [KotTextTypesService, Transition],
                resolveFn: getKotPermissions
            }
        ]
};

export const kotTextTypesName: Ng2StateDeclaration = {
    name: 'kotTextTypesName',
    url: '/configuration/kottexttypes/name',
    component: KotTextTypesComponent,
    params: {
        isCaseType: false
    },
    data: {
        pageTitle: 'kotTextTypes.configuration'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [KotTextTypesService, Transition],
                resolveFn: getKotPermissions
            }
        ]
};