import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { NameViewComponent } from './name-view.component';
import { NameViewService } from './name-view.service';

// tslint:disable-next-line: only-arrow-functions
export function getStateParameters($transition: Transition): any {
    return {
        id: $transition.params().id,
        programId: $transition.params().programId
    };
}

// tslint:disable-next-line: only-arrow-functions
export function getNameViewData(service: NameViewService, $transition): any {
    return service.getNameViewData$(+$transition.params().id, $transition.params().programId).toPromise();
}

// tslint:disable-next-line: variable-name
export const NameViewState: Ng2StateDeclaration = {
    name: 'nameview',
    url: '/nameview/:id?:programId',
    component: NameViewComponent,
    data: {
        pageTitle: 'nameview.pageTitle'
    },
    params: {
        id: {
            type: 'int'
        },
        programId: ''
    },
    resolve:
        [
            {
                token: 'stateParams',
                deps: [Transition],
                resolveFn: getStateParameters
            },
            {
                token: 'nameViewData',
                deps: [NameViewService, Transition],
                resolveFn: getNameViewData
            }
        ]
};
