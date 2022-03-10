// tslint:disable:only-arrow-functions
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { TaskPlannerViewData } from 'search/task-planner/task-planner.data';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { queryContextKeyEnum } from './../common/search-type-config.provider';
import { SearchPresentationComponent } from './search-presentation.component';
import { SearchPresentationViewData } from './search-presentation.model';
import { SearchPresentationService } from './search-presentation.service';

export function getStateParameters($transition: Transition): any {

    let levelUpState = '';

    if ($transition.from().name === 'casesearch' || $transition.params().levelUpState === 'casesearch') {
        levelUpState = 'casesearch';
    }

    if ($transition.from().name === 'taskPlanner' || $transition.from().name === 'taskPlannerSearchBuilder') {
        levelUpState = 'taskPlanner';
    }

    if ($transition.from().name && $transition.from().name === 'search-results') {
        levelUpState = 'search-results';
    }

    return {
        queryKey: $transition.params().queryKey,
        isPublic: $transition.params().isPublic,
        filter: $transition.params().filter,
        queryName: $transition.params().queryName,
        selectedColumns: $transition.params().selectedColumns,
        queryContextKey: $transition.params().queryContextKey,
        activeTabSeq: $transition.params().activeTabSeq,
        levelUpState
    };
}

export function getPresentationViewData(service: SearchPresentationService, transition: Transition): Promise<SearchPresentationViewData> {
    return service.getPresentationViewData(transition.params()).toPromise();
}

export function getTaskPlannerViewData(service: TaskPlannerService, transition: Transition): Promise<TaskPlannerViewData> {
    if (transition.params().queryContextKey === queryContextKeyEnum.taskPlannerSearch.toString()) {
        return service.getTaskPlannerViewData(transition.params().queryKey).toPromise();
    }

    return null;
}

export const searchPresentationState: Ng2StateDeclaration = {
    name: 'searchpresentation',
    url: '/search/presentation?:queryKey&:queryContextKey',
    params: {
        isPublic: null,
        queryKey: null,
        queryContextKey: null,
        filter: null,
        queryName: null,
        q: null,
        levelUpState: undefined,
        selectedColumns: null,
        activeTabSeq: null
    },
    component: SearchPresentationComponent,
    data: {
        pageTitle: 'searchPresentation.pageTitle'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [SearchPresentationService, Transition],
                resolveFn: getPresentationViewData
            },
            {
                token: 'taskPlannerViewData',
                deps: [TaskPlannerService, Transition],
                resolveFn: getTaskPlannerViewData
            },
            {
                token: 'stateParams',
                deps: [Transition],
                resolveFn: getStateParameters
            }
        ]
};