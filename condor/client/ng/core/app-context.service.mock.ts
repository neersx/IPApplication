import { of } from 'rxjs';

export class AppContextServiceMock {
    displayName: string;
    localCurrencyCode: string;
    localDecimalPlaces: number;
    kendoLocale: string;
    appContext: any;
    setHomePageState = jest.fn();
    resetHomePageState = jest.fn();
    // tslint:disable-next-line: typedef
    get appContext$() {
        return of(this.appContext || {
            user: {
                identityId: 9,
                isExternal: false,
                displayName: this.displayName || 'staffName',
                permissions: {
                    canViewReceivables: true,
                    canViewWorkInProgress: true,
                    canShowLinkforInprotechWeb: true
                },
                preferences: {
                    currencyFormat: {
                        localCurrencyCode: this.localCurrencyCode || 'AUD',
                        localDecimalPlaces: this.localDecimalPlaces || 2
                    },
                    kendoLocale: this.kendoLocale || 'en',
                    homePageState: { name: 'current-home' }
                }
            }
        });
    }
}