import { HttpClientMock } from 'mocks';
import { AttachmentConfigurationService } from './attachments-configuration.service';

describe('AttachmentConfigurationService', () => {

    let service: AttachmentConfigurationService;
    let httpMock: HttpClientMock;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        service = new AttachmentConfigurationService(httpMock as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('save$', () => {
        it('should call the api correctly', () => {
            service.save$({ test: 'test' });

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/attachments/settings', { test: 'test' });
        });
    });

    describe('validateUrl$', () => {
        it('should call the api correctly', () => {
            const networkDrives = [
                {
                    test: 'test'
                }
            ];
            service.validateUrl$('test', networkDrives);

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/attachments/settings/validatepath', {
                path: 'test',
                networkDrives
            });
        });
    });

    describe('refreshCache$', () => {
        it('should call the api correctly', () => {
            service.refreshCache$();

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/attachments/settings/refreshcache');
        });
    });
});