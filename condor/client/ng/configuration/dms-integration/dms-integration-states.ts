// tslint:disable: only-arrow-functions
import { HttpClient } from '@angular/common/http';
import { Ng2StateDeclaration } from '@uirouter/angular';
import { DmsIntegrationComponent } from './dms-integration.component';

export function getviewInitialiser(http: HttpClient): Promise<any> {
    return http.get('api/configuration/DMSIntegration/settingsView').toPromise();
}

export const dmsIntegrationState: Ng2StateDeclaration = {
    name: 'dmsIntegration',
    url: '/configuration/dmsintegration',
    component: DmsIntegrationComponent,
    data: {
        pageTitle: 'dmsIntegration.pageTitle'
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