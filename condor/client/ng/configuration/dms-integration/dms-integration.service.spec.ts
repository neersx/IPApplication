import { DmsServiceMock } from 'common/case-name/dms/dms.service.mock';
import { Observable, of } from 'rxjs';
import { DmsIntegrationService } from './dms-integration.service';

describe('DmsIntegrationService', () => {

    let service: DmsIntegrationService;
    let dmsService: DmsServiceMock;
    let httpMock: { post: jest.Mock, get: jest.Mock, put: jest.Mock };
    beforeEach(() => {
        httpMock = { post: jest.fn().mockReturnValue(of({})), get: jest.fn().mockReturnValue(new Observable()), put: jest.fn().mockReturnValue(new Observable()) };
        dmsService = new DmsServiceMock();
        service = new DmsIntegrationService(httpMock as any, dmsService as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('getCredentials', () => {
        it('should return an object if password has value', () => {
            service.password = 's';

            const creds = service.getCredentials();

            expect(creds).not.toBeNull();
        });

        it('should return an object if password has value', () => {
            service.username = 's';

            const creds = service.getCredentials();

            expect(creds).not.toBeNull();
        });

        it('should return an object if password has value', () => {
            service.username = null;
            service.password = null;

            const creds = service.getCredentials();

            expect(creds).toBeNull();
        });
    });

    describe('getManifest', () => {
        it('should call the api correctly', () => {
            service.getManifest({ test: 'test' });

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/dms-integration/settings/get-yaml', { test: 'test' }, {
                observe: 'response',
                responseType: 'arraybuffer'
            });
        });
    });

    describe('save$', () => {
        it('should call the api correctly', () => {
            service.save$({ test: 'test' });

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/DMSIntegration/settings', { test: 'test' });
        });
    });

    describe('sendAllToDms$', () => {
        it('should call the api correctly', () => {
            service.sendAllToDms$('test');

            expect(httpMock.post).toHaveBeenCalledWith('api/dms/send/test', null);
        });
    });

    describe('testCaseWorkspace$$', () => {
        it('should call the api correctly without signing into dms if told not to', () => {
            service.testCaseWorkspace$(123, { test: 'test' }, false);

            expect(httpMock.post).toHaveBeenCalledWith('api/case/testCaseFolders/123', { test: 'test' });
            expect(dmsService.loginDms).not.toHaveBeenCalled();
        });

        it('should call the api correctly without signing into dms if told not to', () => {
            service.testCaseWorkspace$(123, { test: 'test' }, true);

            expect(dmsService.loginDms).toHaveBeenCalled();
            dmsService.loginDms().then(() => {
                expect(httpMock.post).toHaveBeenCalledWith('api/case/testCaseFolders/123', { test: 'test' });
            });
        });
    });

    describe('testNameWorkspace$', () => {
        it('should call the api correctly without signing into dms if told not to', () => {
            service.testNameWorkspace$(123, { test: 'test' }, false);

            expect(httpMock.post).toHaveBeenCalledWith('api/name/testNameFolders/123', { test: 'test' });
            expect(dmsService.loginDms).not.toHaveBeenCalled();
        });

        it('should call the api correctly without signing into dms if told not to', () => {
            service.testNameWorkspace$(123, { test: 'test' }, true);

            expect(dmsService.loginDms).toHaveBeenCalled();
            dmsService.loginDms().then(() => {
                expect(httpMock.post).toHaveBeenCalledWith('api/name/testNameFolders/123', { test: 'test' });
            });
        });
    });

    describe('validateUrl$', () => {
        it('should call the api correctly', () => {
            service.validateUrl$('test', 'type');

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/DMSIntegration/settings/validateurl', {
                url: 'test',
                integrationType: 'type'
            });
        });
    });

    describe('acknowledge$', () => {
        it('should call the api correctly', () => {
            service.acknowledge$('test');

            expect(httpMock.post).toHaveBeenCalledWith('api/dms/job/test/status', null);
        });
    });

    describe('getRequiresCredentials', () => {
        it('should return true for showUsername if database has UsernamePassword', () => {
            const requiresCreds = service.getRequiresCredentials([{ loginType: 'UsernamePassword' }]);

            expect(requiresCreds.showUsername).toBeTruthy();
        });

        it('should return true for showUsername if database has UsernameWithImpersonation', () => {
            const requiresCreds = service.getRequiresCredentials([{ loginType: 'UsernameWithImpersonation' }]);

            expect(requiresCreds.showUsername).toBeTruthy();
        });

        it('should return false for showUsername if database has another type', () => {
            const requiresCreds = service.getRequiresCredentials([{ loginType: 'OtherType' }]);

            expect(requiresCreds.showUsername).toBeFalsy();
        });

        it('should return true for showUsername if database has UsernamePassword', () => {
            const requiresCreds = service.getRequiresCredentials([{ loginType: 'UsernamePassword' }]);

            expect(requiresCreds.showPassword).toBeTruthy();
        });

        it('should return true for showUsername if database has UsernameWithImpersonation', () => {
            const requiresCreds = service.getRequiresCredentials([{ loginType: 'UsernameWithImpersonation' }]);

            expect(requiresCreds.showPassword).toBeFalsy();
        });

        it('should return false for showUsername if database has another type', () => {
            const requiresCreds = service.getRequiresCredentials([{ loginType: 'OtherType' }]);

            expect(requiresCreds.showPassword).toBeFalsy();
        });

        describe('getDataDownload$', () => {
            it('should call the api correctly', () => {
                service.getDataDownload('1');

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/DMSIntegration/settingsView/dataDownload?type=1');
            });
        });
    });
});