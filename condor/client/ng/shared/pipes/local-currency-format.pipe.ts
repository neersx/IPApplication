import { Pipe, PipeTransform } from '@angular/core';
import { formatNumber } from '@progress/kendo-angular-intl';
import { AppContextService } from 'core/app-context.service';
import { Observable } from 'rxjs';
import { map, take } from 'rxjs/operators';

@Pipe({ name: 'localCurrencyFormat' })
export class LocalCurrencyFormatPipe implements PipeTransform {
    accountingService: any;
    localDecimalPlaces: any;
    locale: any;
    localCurrencyCode: any;
    constructor(private readonly appCtx: AppContextService) { }
    transform(value: number, currencyCode?: string, decimalPlaces?: number): Observable<any> {
        return this.appCtx.appContext$
            .pipe(take(1))
            .pipe(map((appCtxValue: any) => {
                this.localCurrencyCode = currencyCode || appCtxValue.user.preferences.currencyFormat.localCurrencyCode;
                this.localDecimalPlaces = decimalPlaces || appCtxValue.user.preferences.currencyFormat.localDecimalPlaces;
                this.locale = appCtxValue.user.preferences.kendoLocale;

                return formatNumber(value, {
                    style: 'accounting',
                    currency: this.localCurrencyCode,
                    currencyDisplay: 'code',
                    minimumFractionDigits: this.localDecimalPlaces,
                    maximumFractionDigits: this.localDecimalPlaces
                }, this.locale);
            }));
    }
}