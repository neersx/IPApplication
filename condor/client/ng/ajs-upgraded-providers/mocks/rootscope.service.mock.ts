export class RootScopeServiceMock {
    displayName: string;
    localCurrencyCode: string;
    localDecimalPlaces: number;
    kendoLocale: string;
    isHosted = true;
    rootScope = {
        appContext: {
            user: {
                displayName: this.displayName || 'staffName',
                permissions: { canViewReceivables: true, canViewWorkInProgress: true },
                preferences: {
                    currencyFormat: {
                        localCurrencyCode: this.localCurrencyCode || 'AUD',
                        localDecimalPlaces: this.localDecimalPlaces || 2
                    },
                    kendoLocale: this.kendoLocale || 'en'
                }
            }
        },
        isHosted: true
    };
}