import { Observable } from 'rxjs';
import { ReportingServicesSetting } from './reporting-services-integration-data';
import { ReportingIntegrationSettingsService } from './reporting-services-integration.service';

describe('ReportingIntegrationSettingsService', () => {

    let service: ReportingIntegrationSettingsService;
    const httpMock = { post: jest.fn(), get: jest.fn().mockReturnValue(new Observable()) };
    const _baseUrl = 'api/configuration/reportingservicessetting';

    beforeEach(() => {
        service = new ReportingIntegrationSettingsService(httpMock as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });

    it('validate getSettings', () => {
        service.getSettings();
        expect(httpMock.get).toHaveBeenCalledWith(_baseUrl);
    });

    it('validate save', () => {
        const settings = new ReportingServicesSetting();
        service.save(settings);
        expect(httpMock.post).toHaveBeenCalledWith(_baseUrl + '/save', settings);
    });

    it('validate testConnection', () => {
        const settings = new ReportingServicesSetting();
        service.testConnection(settings);
        expect(httpMock.post).toHaveBeenCalledWith(_baseUrl + '/connection', settings);
    });
});