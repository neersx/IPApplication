// tslint:disable:only-arrow-functions
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { SearchColumnsComponent } from './search-columns-component';
import { QueryColumnViewData } from './search-columns.model';
import { SearchColumnsService } from './search-columns.service';

export function getColumnsViewData(service: SearchColumnsService, $transition: Transition): Promise<QueryColumnViewData> {
    return service.getColumnsViewData($transition.params()).toPromise();
}

export const searchColumnsState: Ng2StateDeclaration = {
    name: 'searchcolumns',
    url: '/search/columns?:queryKey&:queryContextKey',
    params: {
        isPublic: null,
        queryKey: null,
        queryContextKey: null,
        filter: null,
        queryName: null,
        q: null,
        levelUpState: undefined,
        selectedColumns: null
    },
    component: SearchColumnsComponent,
    data: {
        pageTitle: 'SearchColumns.pageTitle'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [SearchColumnsService, Transition],
                resolveFn: getColumnsViewData
            }
        ]
};