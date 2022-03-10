import { TranslateLoader } from '@ngx-translate/core';
import { of } from 'rxjs';
import { TranslationService } from '../ajs-upgraded-providers/translation.service.provider';

export class CustomTranslationLoader implements TranslateLoader {
    constructor(private readonly service: TranslationService) {

    }
    getTranslation(lang: string): import('rxjs').Observable<any> {
        return of(this.service.getTranslationTable(lang));
    }
}
