// tslint:disable: only-arrow-functions
import { HttpClient } from '@angular/common/http';
import { Ng2StateDeclaration } from '@uirouter/angular';
import { AttachmentsComponent } from './attachments.component';

export function getviewInitialiser(http: HttpClient): Promise<any> {
    return http.get('api/configuration/attachments/settingsView').toPromise();
}

export const attachmentsConfigurationState: Ng2StateDeclaration = {
    name: 'attachmentsIntegration',
    url: '/configuration/attachments',
    component: AttachmentsComponent,
    data: {
        pageTitle: 'attachmentsIntegration.pageTitle'
    },
    resolve:
        [
            {
                token: 'viewInitialiser',
                deps: [HttpClient],
                resolveFn: getviewInitialiser
            }
        ]
};