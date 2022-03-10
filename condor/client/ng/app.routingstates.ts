import { Ng2StateDeclaration } from '@uirouter/angular';

export const appCaseRoute: Ng2StateDeclaration = {
    name: 'case.*',
    url: '/case2',
    loadChildren: () => import('./search/case/case-search.module').then(m => m.CaseSearchModule)
};