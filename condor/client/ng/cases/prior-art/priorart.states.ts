import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { PriorArtMaintenanceComponent } from './priorart-maintenance/priorart-maintenance.component';
import { PriorArtComponent } from './priorart.component';
import { PriorArtService } from './priorart.service';

// tslint:disable-next-line: only-arrow-functions
export function getStateParameters($transition: Transition): any {
    return {
        sourceId: $transition.params().priorartId || $transition.params().sourceId,
        caseKey: $transition.params().caseKey,
        showCloseButton: (!!($transition.params().priorartId || $transition.params().sourceId)) && $transition.params().showCloseButton,
        goToStep: $transition.params().gotToStep
    };
}
// tslint:disable-next-line: only-arrow-functions
export function getTranslations$(service: PriorArtService): any {
    return service.getPriorArtTranslations$().toPromise();
}

// tslint:disable-next-line: only-arrow-functions
export function getPriorArtData$(service: PriorArtService, $transition: Transition): any {
    const sourceId = $transition.params().priorartId || $transition.params().sourceId;
    const caseKey = $transition.params().caseKey;

    return service.getPriorArtData$(sourceId, caseKey).toPromise();
}

// tslint:disable-next-line: variable-name
export const PriorArtState: Ng2StateDeclaration = {
    name: 'priorArt',
    url: '/priorart?/:sourceId/:caseKey',
    component: PriorArtComponent,
    data: {
        pageTitle: 'caseview.priorArt.header'
    },
    params: {
        sourceId: {
            squash: true,
            type: 'int',
            value: null
        },
        caseKey: {
            squash: true,
            type: 'int',
            value: null
        },
        priorartId: null,
        showCloseButton: false
    },
    resolve:
        [
            {
                token: 'stateParams',
                deps: [Transition],
                resolveFn: getStateParameters
            },
            {
                token: 'translationsList',
                deps: [PriorArtService],
                resolveFn: getTranslations$
            },
            {
                token: 'priorArtData',
                deps: [PriorArtService, Transition],
                resolveFn: getPriorArtData$
            }
        ]
};

// tslint:disable-next-line:variable-name
export const PriorArtMaintenanceState: Ng2StateDeclaration = {
    name: 'priorArtMaintenance',
    url: '/priorartmaintenance?/:priorartId/:caseKey',
    redirectTo: 'referenceManagement'
};

// tslint:disable-next-line:variable-name
export const ReferenceManagementState: Ng2StateDeclaration = {
    name: 'referenceManagement',
    url: '/reference-management?/:priorartId/:caseKey',
    component: PriorArtMaintenanceComponent,
    data: {
        pageTitle: 'caseview.priorArt.header'
    },
    params: {
        priorartId: {
            squash: true,
            type: 'int',
            value: null
        },
        caseKey: {
            squash: true,
            type: 'int',
            value: null
        },
        sourceId: null,
        goToStep: null
    },
    resolve:
        [
            {
                token: 'stateParams',
                deps: [Transition],
                resolveFn: getStateParameters
            },
            {
                token: 'translationsList',
                deps: [PriorArtService],
                resolveFn: getTranslations$
            },
            {
                token: 'priorArtData',
                deps: [PriorArtService, Transition],
                resolveFn: getPriorArtData$
            }
        ]
};