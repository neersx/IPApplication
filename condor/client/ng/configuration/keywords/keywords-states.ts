// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration } from '@uirouter/angular';
import { KeywordsComponent } from './keywords.component';
import { KeywordsPermissions } from './keywords.model';
import { KeywordsService } from './keywords.service';

export function getViewData(service: KeywordsService): Promise<KeywordsPermissions> {
    return service.getViewData().toPromise();
}

export const keywords: Ng2StateDeclaration = {
    name: 'keywords',
    url: '/configuration/keywords',
    component: KeywordsComponent,
    data: {
        pageTitle: 'keywords.maintenance'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [KeywordsService],
                resolveFn: getViewData
            }
        ]
};