// tslint:disable:only-arrow-functions
import { Ng2StateDeclaration, StateService, Transition } from '@uirouter/angular';
import { LocalSettings } from 'core/local-settings';
import * as _ from 'underscore';
import { RoleSearchComponent } from './roles/role-search.component';
import { RoleSearchService } from './roles/role-search.service';
import { RoleDetailsComponent } from './roles/roles-details/role-details.component';
export function getRolesViewData(service: RoleSearchService): Promise<any> {
    return service.getRolesViewData().toPromise();
}

export function runSearch(service: RoleSearchService, localSettings: LocalSettings, transition: Transition, stateService: StateService): Promise<any> {
    const fromParams = transition.params('from');
    if (fromParams && !fromParams.id && transition.from().name !== 'roles') {
        return service.runSearch(localSettings.keys.navigation.searchCriteria.getLocal, localSettings.keys.navigation.queryParams.getLocal).toPromise();
    }
}
export const userConfigurationState: Ng2StateDeclaration = {
    name: 'roles',
    url: '/user-configuration/roles',
    params: {},
    component: RoleSearchComponent,
    data: {
        pageTitle: 'picklist.roleSearch'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [RoleSearchService],
                resolveFn: getRolesViewData
            }
        ]
};

export const roleDetailState: Ng2StateDeclaration = {
    name: 'role-details',
    url: '/user-configuration/roles/?:id',
    params: {
        id: {
            type: 'int'
        },
        rowKey: undefined
    },
    component: RoleDetailsComponent,
    data: {
        pageTitle: 'Role Maintenance'
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
                deps: [RoleSearchService],
                resolveFn: getRolesViewData
            }
            ,
            {
                token: 'search',
                deps: [RoleSearchService, LocalSettings, Transition, StateService],
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