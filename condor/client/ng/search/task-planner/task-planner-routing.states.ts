import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { SearchPresentationPersistenceService } from 'search/presentation/search-presentation.persistence.service';
import * as _ from 'underscore';
import { SavedTaskPlannerData, SearchBuilderViewData } from './task-planner-search-builder/search-builder.data';
import { TaskPlannerSearchBuilderComponent } from './task-planner-search-builder/task-planner-search-builder.component';
import { TaskPlannerComponent } from './task-planner.component';
import { TaskPlannerViewData } from './task-planner.data';
import { TaskPlannerService } from './task-planner.service';

// tslint:disable-next-line: only-arrow-functions
export function getSearchResultsViewData(service: TaskPlannerService, transition: Transition): Promise<TaskPlannerViewData> {

    return service.getSearchResultsViewData().toPromise();
}

// tslint:disable-next-line: only-arrow-functions
export function getPreviousStateParams(transition: Transition): any {
    return {
        name: 'taskPlanner',
        params: transition.params()
    };
}

// tslint:disable-next-line: only-arrow-functions
export function getSearchBuilderViewData(service: TaskPlannerService): Promise<SearchBuilderViewData> {
    return service.getSearchBuilderViewData().toPromise();
}

// tslint:disable-next-line: only-arrow-functions
export function getSavedTaskPlannerData(service: TaskPlannerService, transition: Transition): Promise<SavedTaskPlannerData> {
    return service.getSavedTaskPlannerData(transition.params()).toPromise();
}

// tslint:disable-next-line: only-arrow-functions
export function getPreviousState(transition: Transition, taskPlannerService: TaskPlannerService, searchPresentationPersistenceService: SearchPresentationPersistenceService): void {

    taskPlannerService.previousStateParam = null;
    if (transition.params() && transition.params().levelUpClicked) {
        taskPlannerService.previousStateParam = taskPlannerService.taskPlannerStateParam ? taskPlannerService.taskPlannerStateParam : {};
        taskPlannerService.previousStateParam.searchBuilder = true;
    } else if (transition.params() && transition.params().filterCriteria && transition.params().searchBuilder) {
        taskPlannerService.previousStateParam = transition.params();
        if ((taskPlannerService.previousStateParam.formData && !_.isEmpty(taskPlannerService.previousStateParam.formData) && (taskPlannerService.previousStateParam.isFormDirty || taskPlannerService.previousStateParam.isSelectedColumnChange))) {
            taskPlannerService.previousStateParam.queryKey = null;
        }
    } else if (!transition.params().searchBuilder) {
        searchPresentationPersistenceService.clear();
    }
}

// tslint:disable-next-line: variable-name
export const TaskPlannerState: Ng2StateDeclaration = {
    name: 'taskPlanner',
    url: '/task-planner',
    component: TaskPlannerComponent,
    data: {
        pageTitle: 'taskPlanner.pageTitle'
    },
    params: {
        filterCriteria: null,
        searchBuilder: null,
        formData: null,
        selectedColumns: null,
        activeTabSeq: null,
        levelUpClicked: null,
        isFormDirty: null,
        queryKey: null,
        searchName: null,
        isSelectedColumnChange: null
    },
    resolve:
        [
            {
                token: 'previousState',
                deps: [Transition, TaskPlannerService, SearchPresentationPersistenceService],
                resolveFn: getPreviousState
            },
            {
                token: 'viewData',
                deps: [TaskPlannerService, Transition],
                resolveFn: getSearchResultsViewData
            }
        ]
};

// tslint:disable-next-line: variable-name
export const SearchBuilderState: Ng2StateDeclaration = {
    name: 'taskPlannerSearchBuilder',
    url: '/task-planner/search-builder?:queryKey',
    component: TaskPlannerSearchBuilderComponent,
    data: {
        pageTitle: 'taskPlanner.searchBuilder.pageTitle'
    },
    params: {
        filterCriteria: null,
        savedSearch: null,
        names: null,
        nameGroups: null,
        timePeriod: null,
        formData: null,
        selectedColumns: null,
        backFromSearchBuilder: null,
        activeTabSeq: null,
        queryKey: null,
        searchName: null,
        isPicklistSearch: false
    },
    resolve:
        [
            {
                token: 'previousStateParams', deps: [Transition], resolveFn: getPreviousStateParams
            },
            {
                token: 'viewData',
                deps: [TaskPlannerService],
                resolveFn: getSearchBuilderViewData
            },
            {
                token: 'savedTaskPlannerData',
                deps: [TaskPlannerService, Transition],
                resolveFn: getSavedTaskPlannerData
            }
        ]
};