// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { SanityCheckConfigurationComponent } from './sanity-check-configuration.component';
import { SanityCheckConfigurationService } from './sanity-check-configuration.service';
import { SanityCheckConfigurationMaintenanceComponent } from './sanity-check-maintenance/sanity-check-maintenance.component';
import { SanityCheckMaintenanceService } from './sanity-check-maintenance/sanity-check-maintenance.service';

export function getViewInitializer(service: SanityCheckConfigurationService, $transition: Transition): Promise<any> {
    return service.getViewData$($transition.params().matchType).toPromise();
}

export function getMaintenanceViewInitializer(service: SanityCheckMaintenanceService, $transition: Transition): Promise<any> {
    return service.getViewData$($transition.params().matchType, $transition.params().id).toPromise();
}

export function getStateParameters($transition: Transition): any {
    return {
        matchType: $transition.params().matchType,
        id: $transition.params().id,
        levelUpState: 'sanityCheck',
        isLevelUp: $transition.params().isLevelUp,
        rowKey: $transition.params().rowKey
    };
}

export const sanityCheckConfigurationState: Ng2StateDeclaration = {
    name: 'sanityCheck',
    url: '/configuration/sanity-check/:matchType',
    component: SanityCheckConfigurationComponent,
    data: {
        pageTitle: 'sanityCheck.configurations.pageTitle'
    },
    params: {
        matchType: '',
        isLevelUp: false
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            },
            {
                token: 'viewInitialiser',
                deps: [SanityCheckConfigurationService, Transition],
                resolveFn: getViewInitializer
            }
        ]
};

export const sanityCheckConfigurationMaintenanceInsertState: Ng2StateDeclaration = {
    name: 'sanityCheckMaintenanceInsert',
    url: '/configuration/sanity-check/maintenance/:matchType',
    component: SanityCheckConfigurationMaintenanceComponent,
    data: {
        pageTitle: 'sanityCheck.configurations.maintenance.pageTitleAdd'
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            },
            {
                token: 'viewInitialiser',
                deps: [SanityCheckConfigurationService, Transition],
                resolveFn: getViewInitializer
            }
        ]
};

export const sanityCheckConfigurationMaintenanceEditState: Ng2StateDeclaration = {
    name: 'sanityCheckMaintenanceEdit',
    url: '/configuration/sanity-check/maintenance/:matchType/:id',
    component: SanityCheckConfigurationMaintenanceComponent,
    data: {
        pageTitle: 'sanityCheck.configurations.maintenance.pageTitleEdit'
    },
    params: {
        matchType: '',
        rowKey: null,
        id: null,
        levelUpState: 'sanityCheck'
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            },
            {
                token: 'viewData',
                deps: [SanityCheckMaintenanceService, Transition],
                resolveFn: getMaintenanceViewInitializer
            }
        ]
};