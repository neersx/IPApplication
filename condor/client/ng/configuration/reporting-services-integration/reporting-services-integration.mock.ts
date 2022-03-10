import { Observable } from 'rxjs';

export class ReportingIntegrationSettingsServiceMock {
    getSettings = jest.fn().mockReturnValue(new Observable());
    save = jest.fn().mockReturnValue(new Observable());
    testConnection = jest.fn().mockReturnValue(new Observable());
}