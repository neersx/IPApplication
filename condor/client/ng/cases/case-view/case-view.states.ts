// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { resolve } from 'dns';
import { CaseDetailService } from './case-detail.service';
import { CaseViewComponent } from './case-view.component';
import { CaseViewViewData } from './view-data.model';

export function getViewData(service: CaseDetailService, $transition): Promise<CaseViewViewData> {
    return getStateParameters(service, $transition).then(
        parameters => {
            return service.getOverview$(parameters.id, parameters.rowKey).toPromise();
        }
    );
}

export function getStateParameters(service: CaseDetailService, $transition: Transition): Promise<any> {
    return new Promise((resolveData, reject) => {
        let levelUpState = $transition?.from().name === 'portal2' || $transition?.params().levelUpState === 'portal2' ? 'portal2' : 'search-results';
        if ($transition.from().name === 'sanity-check-results') {
            levelUpState = 'sanity-check-results';
        }

        let id = $transition.params().id;
        if (id == null && $transition.params().caseRef != null) {
            service.getCaseId$($transition.params().caseRef).then(val => {
                id = val;

                resolveData({
                    id,
                    programId: $transition.params().programId,
                    section: $transition.params().section,
                    rowKey: $transition.params().rowKey,
                    isE2e: $transition.params().isE2e,
                    levelUpState
                });
            }).catch(reject);
        } else {
            resolveData({
                id,
                programId: $transition.params().programId,
                section: $transition.params().section,
                rowKey: $transition.params().rowKey,
                isE2e: $transition.params().isE2e,
                levelUpState
            });
        }
    });
}

// tslint:disable-next-line: only-arrow-functions
export function getIppAvailability(service: CaseDetailService, $transition$): Promise<any> {
    return getStateParameters(service, $transition$).then(val => service.getIppAvailability$(val.id).toPromise());
}

// tslint:disable-next-line: only-arrow-functions
export function getScreenControl(service: CaseDetailService, $transition$): Promise<any> {
    return getStateParameters(service, $transition$).then(val => service.getScreenControl$(val.id, val.programId).toPromise());
}

// tslint:disable-next-line: only-arrow-functions
export function getCaseViewData(service: CaseDetailService): any {
    return service.getCaseViewData$().toPromise();
}

export const caseViewState: Ng2StateDeclaration = {
    name: 'caseview',
    url: '/caseview/:id?:programId:section:isE2e:caseRef',
    component: CaseViewComponent,
    params: {
        id: {
            type: 'int',
            squash: true,
            value: null
        },
        caseRef: undefined,
        rowKey: undefined,
        section: '',
        programId: '',
        levelUpState: undefined,
        isE2e: {
            type: 'bool'
        }
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [CaseDetailService, Transition], resolveFn: getStateParameters
            },
            {
                token: 'viewData',
                deps: [CaseDetailService, Transition],
                resolveFn: getViewData
            },
            {
                token: 'ippAvailability',
                deps: [CaseDetailService, Transition],
                resolveFn: getIppAvailability
            },
            {
                token: 'screenControl',
                deps: [CaseDetailService, Transition],
                resolveFn: getScreenControl
            },
            {
                token: 'caseViewData',
                deps: [CaseDetailService],
                resolveFn: getCaseViewData
            }
        ],
    data: {
        pageTitle: 'caseview.pageTitle',
        hasContextNavigation: true
    }
};
