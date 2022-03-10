import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { RecentCasesComponent } from './recent-cases/recent-cases.component';

// tslint:disable-next-line:only-arrow-functions
export function getSelectedRowKey(transition: Transition): string {
    return transition.params('from').rowKey;
}

export const portal2State: Ng2StateDeclaration = {
    name: 'portal2',
    url: '/portal2',
    params: {
        rowKey: undefined
    },
    component: RecentCasesComponent,
    data: {
        pageTitle: 'defaultpageTitle'
    },
    resolve: [{
        token: 'rowKey',
        deps: [Transition],
        resolveFn: getSelectedRowKey
    }]
};