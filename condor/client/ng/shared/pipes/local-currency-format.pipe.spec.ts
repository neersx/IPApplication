import { NO_ERRORS_SCHEMA } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import * as kendoIntl from '@progress/kendo-angular-intl';
import { AppContextService } from 'core/app-context.service';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { LocalCurrencyFormatPipe } from './local-currency-format.pipe';

describe('Local currency format pipe', () => {
    let pipe: LocalCurrencyFormatPipe;
    beforeEach(() => {
        TestBed.configureTestingModule({
            schemas: [NO_ERRORS_SCHEMA],
            providers: [
                { provide: AppContextService, useClass: AppContextServiceMock }
            ]
        });
    });

    it('should create an instance', () => {
        pipe = new LocalCurrencyFormatPipe(new AppContextServiceMock() as any);
        expect(pipe).toBeTruthy();
    });

    it('should set the right values of pipe from appCtx', () => {
        spyOn(kendoIntl, 'formatNumber').and.returnValue('22,000 BFG');
        const appContextMock = new AppContextServiceMock();
        appContextMock.localCurrencyCode = 'BFG';
        appContextMock.localDecimalPlaces = 3;
        appContextMock.kendoLocale = 'xyz';

        pipe = new LocalCurrencyFormatPipe(appContextMock as any);
        kendoIntl.setData({ name: 'en' });
        pipe.transform(22, null).subscribe();
        expect(pipe.localCurrencyCode).toBe('BFG');
        expect(pipe.localDecimalPlaces).toBe(3);
        expect(pipe.locale).toBe('xyz');
        expect(kendoIntl.formatNumber).toHaveBeenCalledWith(22, {
            style: 'accounting',
            currency: 'BFG',
            currencyDisplay: 'code',
            minimumFractionDigits: 3,
            maximumFractionDigits: 3
        }, 'xyz');
    });
});
