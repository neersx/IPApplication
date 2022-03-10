// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration } from '@uirouter/angular';
import { RecordalTypeComponent } from './recordal-type.component';
import { RecordalTypePermissions } from './recordal-type.model';
import { RecordalTypeService } from './recordal-type.service';

export function getViewData(service: RecordalTypeService): Promise<RecordalTypePermissions> {
    return service.getViewData().toPromise();
}

export const recordalType: Ng2StateDeclaration = {
    name: 'recordalType',
    url: '/configuration/recordal-types',
    component: RecordalTypeComponent,
    data: {
        pageTitle: 'recordalType.maintenance'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [RecordalTypeService],
                resolveFn: getViewData
            }
        ]
};