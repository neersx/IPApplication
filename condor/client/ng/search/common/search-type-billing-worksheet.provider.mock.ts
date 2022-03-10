import { Observable } from 'rxjs';

export class SearchTypeBillingWorksheetProvidereMock {
    initializeContext = jest.fn();
    getConfigurationActionMenuItems = jest.fn();
}

export class SearchTypeBillingWorksheetProvidereServiceMock {
    getReportProviderInfo = jest.fn().mockReturnValue(new Observable());
    genrateBillingWorkSheet = jest.fn().mockReturnValue(new Observable());
}