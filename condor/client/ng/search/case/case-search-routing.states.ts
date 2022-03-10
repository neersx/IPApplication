// tslint:disable:only-arrow-functions
// tslint:disable:variable-name
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { BulkUpdateComponent } from './bulk-update/bulk-update.component';
import { BulkUpdateViewData } from './bulk-update/bulk-update.data';
import { BulkUpdateService } from './bulk-update/bulk-update.service';
import { CaseSearchComponent } from './case-search.component';
import { CaseSavedSearchData, CaseSearchViewData, CaseStateParams } from './case-search.data';
import { CaseSearchService } from './case-search.service';
import { SanityCheckResultsComponent } from './results/sanity-check/sanity-check-results.component';

export const CaseState: Ng2StateDeclaration = {
    name: 'case',
    url: '/case',
    redirectTo: 'casesearch'
};

export function getCaseSeachViewData(service: CaseSearchService, transition: Transition): Promise<CaseSearchViewData> {
    return service.getCaseSearchViewData(transition.params()).toPromise();
}

export function getCaseSavedSearchData(service: CaseSearchService, transition: Transition): Promise<CaseSavedSearchData> {
    const data = service.getCaseSavedSearchData(transition.params());

    return data ? data.toPromise() : null;
}

export function getBulkUpdateViewData(service: BulkUpdateService): Promise<BulkUpdateViewData> {
    return service.getBulkUpdateViewData().toPromise();
}

export function getPreviousState(transition: Transition,
    caseSearchService: CaseSearchService): any {
    let params: CaseStateParams = null;
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

export const CaseSearchState: Ng2StateDeclaration = {
    name: 'casesearch',
    url: '/case/search?:queryKey',
    params: {
        queryKey: null,
        canEdit: false,
        returnFromCaseSearchResults: false
    },
    component: CaseSearchComponent,
    data: {
        pageTitle: 'caseSearch.pageTitle'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [CaseSearchService, Transition],
                resolveFn: getCaseSeachViewData
            },
            {
                token: 'savedSearchData',
                deps: [CaseSearchService, Transition],
                resolveFn: getCaseSavedSearchData
            }
        ]
};

export const CaseBulkUpdate: Ng2StateDeclaration = {
    name: 'bulk-edit',
    url: '/bulkupdate',
    component: BulkUpdateComponent,
    data: {
        pageTitle: 'caseSearchResults.pageTitle'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [BulkUpdateService],
                resolveFn: getBulkUpdateViewData
            },
            {
                token: 'previousState',
                deps: [Transition, CaseSearchService],
                resolveFn: getPreviousState
            }
        ]
};

export function getSanityCheckStateParams($transition: Transition): any {
    return {
        id: $transition.params().id,
        levelUpState: $transition.from().name
    };
}

export const SanityCheckResults: Ng2StateDeclaration = {
    name: 'sanity-check-results',
    url: '/sanity-check-results/:id',
    component: SanityCheckResultsComponent,
    data: {
        pageTitle: 'sanityCheck.pageTitle'
    },
    params: {
        id: {
            type: 'int'
        }
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getSanityCheckStateParams
            },
            {
                token: 'previousState',
                deps: [Transition, CaseSearchService],
                resolveFn: getPreviousState
            }

        ]
};