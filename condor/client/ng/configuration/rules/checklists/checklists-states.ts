import * as angular from '@uirouter/angular';
import { ChecklistSearchComponent } from './search/checklist-search.component';
import { ChecklistSearchService } from './search/checklist-search.service';

// tslint:disable-next-line: only-arrow-functions
export function getChecklistConfigurationViewData(service: ChecklistSearchService): Promise<any> {
    return service.getCriteriaSearchViewData$().toPromise();
}

export const checklistConfigurationState: angular.Ng2StateDeclaration = {
    name: 'checklistConfiguration',
    url: '/configuration/rules/checklist-configuration',
    component: ChecklistSearchComponent,
    params: {
        rowKey: null,
        isLevelUp: false
    },
    resolve: [
        {
            token: 'viewData', deps: [ChecklistSearchService], resolveFn: getChecklistConfigurationViewData
        }
    ],
    data: {
        pageTitle: 'checklistConfiguration.pageTitle'
    }
};
