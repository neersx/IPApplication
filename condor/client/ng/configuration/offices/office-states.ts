// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration } from '@uirouter/angular';
import { OfficeComponent } from './offices.component';
import { OfficePermissions } from './offices.model';
import { OfficeService } from './offices.service';

export function getViewData(service: OfficeService): Promise<OfficePermissions> {
    return service.getViewData().toPromise();
}

export const offices: Ng2StateDeclaration = {
    name: 'offices',
    url: '/configuration/offices',
    component: OfficeComponent,
    data: {
        pageTitle: 'office.maintenance.title'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [OfficeService],
                resolveFn: getViewData
            }
        ]
};