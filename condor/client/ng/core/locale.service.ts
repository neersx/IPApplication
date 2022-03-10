import { HttpClient } from '@angular/common/http';
import { Inject, Injectable, LOCALE_ID } from '@angular/core';
import { CldrIntlService, IntlService, setData } from '@progress/kendo-angular-intl';

@Injectable()
export class LocaleService {
    private readonly url = 'condor/kendo-intl/{0}/all.json';
    private readonly loaded: any = {};
    locale: string;
    constructor(
        private readonly http: HttpClient,
        private readonly intl: IntlService,
        @Inject(LOCALE_ID) public localeId: string
    ) {
        this.loaded[localeId] = true;
    }

    set(localeId: string): void {
        if (this.loaded[localeId]) {
            this.setLocale(localeId);

            return;
        }
        this.locale = localeId;

        this.http.get(this.intl.format(this.url, localeId))
            .subscribe(
                result => {
                    setData(result);
                    this.loaded[localeId] = true;
                    this.setLocale(localeId);
                }
            );
    }

    private setLocale(localeId: string): void {
        (this.intl as CldrIntlService).localeId = localeId;
        this.localeId = localeId;
    }
}
