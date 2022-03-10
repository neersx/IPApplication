// tslint:disable:only-arrow-functions
// tslint:disable:variable-name
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { SearchResultsComponent } from './search-results.component';
import { SearchResultsViewData, StateParams } from './search-results.data';
import { SearchResultsService } from './search-results.service';

export function getSearchResultsViewData(service: SearchResultsService, transition: Transition): Promise<SearchResultsViewData> {
    return service.getSearchResultsViewData(transition.params()).toPromise();
}

export function getPreviousState(transition: Transition, caseSearchService: SearchResultsService): any {
    let params: StateParams = null;
    if (transition.params().searchQueryKey && transition.params().rowKey) {
        params = caseSearchService.previousState;
    } else if (transition.from().name !== '') {
        params = {
            name: transition.from().name,
            params: transition.params('from')
        };
    } else {
        params = null;
    }
    caseSearchService.previousState = params;

    return params;
}

export const searchResultsState: Ng2StateDeclaration = {
    name: 'search-results',
    url: '/search-result?q&queryKey&queryContext',
    params: {
        filter: null,
        queryKey: null,
        searchQueryKey: false,
        rowKey: undefined,
        clearSelection: undefined,
        isLevelUp: undefined,
        hasDueDatePresentation: false,
        selectedColumns: null,
        presentationType: null,
        globalProcessKey: null,
        backgroundProcessResultTitle: null,
        queryContext: null,
        checkPersistedData: null
    },
    component: SearchResultsComponent,
    data: {
        pageTitle: 'caseSearchResults.pageTitle'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [SearchResultsService, Transition],
                resolveFn: getSearchResultsViewData
            },
            {
                token: 'previousState',
                deps: [Transition, SearchResultsService],
                resolveFn: getPreviousState
            }
        ]
};