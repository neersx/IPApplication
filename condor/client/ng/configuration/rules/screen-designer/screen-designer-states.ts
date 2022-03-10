// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { InheritanceComponent } from './case/inheritance/inheritance.component';
import { MaintenanceComponent } from './case/maintenance/maintenance.component';
import { ScreenDesignerSearchComponent, SearchStateParams } from './case/search/search.component';
import { ScreenDesignerCriteriaDetails, ScreenDesignerService, ScreenDesignerViewData } from './screen-designer.service';

// tslint:disable-next-line: only-arrow-functions
export function getScreenDesignerViewData(service: ScreenDesignerService): Promise<ScreenDesignerViewData> {
    return service.getCriteriaSearchViewData$().toPromise();
}
export function getCriteriaViewData(service: ScreenDesignerService, $transition: Transition): Promise<any> {
    return service.getCriteriaMaintenanceViewData$($transition.params().id).toPromise();
}
export function getMaintenanceStateParameters($transition: Transition, service: ScreenDesignerService): any {
    return {
        id: $transition.params().id,
        rowKey: $transition.params().rowKey,
        retrieveSearch: $transition.params().retrieveSearch,
        levelUpState: service.previousState() || 'screenDesigner'
    };
}

export function getInheritanceStateParameters($transition: Transition, service: ScreenDesignerService): any {
    return {
        id: $transition.params().id,
        rowKey: $transition.params().rowKey,
        retrieveSearch: $transition.params().retrieveSearch,
        levelUpState: service.previousState() || 'screenDesigner'
    };
}

export function getSearchStateParams($transition: Transition): SearchStateParams {
    return {
        rowKey: $transition.params().rowKey,
        isLevelUp: $transition.params().isLevelUp
    };
}

export function getCriteriaDetails(service: ScreenDesignerService, $transition$): Promise<ScreenDesignerCriteriaDetails> {
    return service.getCriteriaDetails$(getMaintenanceStateParameters($transition$, service).id).toPromise();
}

export const screenDesignerState: Ng2StateDeclaration = {
    name: 'screenDesigner',
    url: '/configuration/rules/screen-designer/cases',
    component: ScreenDesignerSearchComponent,
    params: {
        rowKey: null,
        isLevelUp: false
    },
    resolve: [
        {
            token: 'viewData', deps: [ScreenDesignerService], resolveFn: getScreenDesignerViewData
        },
        {
            token: 'stateParams', deps: [Transition], resolveFn: getSearchStateParams
        }
    ],
    data: {
        pageTitle: 'screenDesignerCases.pageTitle'
    }
};

export const maintenanceState: Ng2StateDeclaration = {
    name: 'screenDesignerCaseCriteria',
    url: '/configuration/rules/screen-designer/cases/:id?',
    component: MaintenanceComponent,
    params: {
        id: null,
        rowKey: null
    },
    resolve: [
        {
            token: 'viewData', deps: [ScreenDesignerService, Transition], resolveFn: getCriteriaViewData
        },
        {
            token: 'screenCriteriaDetails', deps: [ScreenDesignerService, Transition], resolveFn: getCriteriaDetails
        },
        {
            token: 'stateParams', deps: [Transition, ScreenDesignerService], resolveFn: getMaintenanceStateParameters
        }
    ],
    data: {
        pageTitle: 'screenDesignerCases.pageTitle'
    }
};
export const inheritanceState: Ng2StateDeclaration = {
    name: 'screenDesignerCaseInheritance',
    url: '/configuration/rules/screen-designer/cases/inheritance/:id?',
    component: InheritanceComponent,
    params: {
        id: null,
        rowKey: null
    },
    resolve: [
        {
            token: 'viewData', deps: [Transition, ScreenDesignerService], resolveFn: getInheritanceStateParameters
        },
        {
            token: 'stateParams', deps: [Transition], resolveFn: getSearchStateParams
        }
    ],
    data: {
        pageTitle: 'screenDesignerCases.pageTitle'
    }
};