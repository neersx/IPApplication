import { Ng2StateDeclaration } from '@uirouter/angular';
import { DisbursementDissectionComponent } from './disbursement-dissection.component';

// tslint:disable-next-line: variable-name
export const DisbursementDissectionState: Ng2StateDeclaration = {
    name: 'disbursementDissection',
    url: '/accounting/wip-disbursements',
    component: DisbursementDissectionComponent,
    data: {
        pageTitle: 'accounting.wip.disbursements.pageTitle'
    }
};