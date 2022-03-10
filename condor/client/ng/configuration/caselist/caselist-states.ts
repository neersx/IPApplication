import { Ng2StateDeclaration } from '@uirouter/angular';
import { CaseListViewData } from './caselist-data';
import { CaselistMaintenanceService } from './caselist-maintenance.service';
import { CaselistMaintenanceComponent } from './caselist-maintenance/caselist-maintenance.component';

// tslint:disable-next-line: only-arrow-functions
export function getCaselistViewData(service: CaselistMaintenanceService): Promise<CaseListViewData> {
    return service.getViewdata().toPromise();
}

export const caselistMaintenanceState: Ng2StateDeclaration = {
    name: 'caselistMaintenance',
    url: '/configuration/caselist-maintenance',
    component: CaselistMaintenanceComponent,
    data: {
        pageTitle: 'picklist.caselist.caselistMaintenance'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [CaselistMaintenanceService],
                resolveFn: getCaselistViewData
            }
        ]
};