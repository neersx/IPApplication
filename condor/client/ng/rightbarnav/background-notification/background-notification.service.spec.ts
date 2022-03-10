import { HttpClientMock, TranslateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { FileDownloadServiceMock } from 'shared/shared-services/file-download.service.mock';
import { BackgroundNotificationService } from './background-notification.service';

describe('BackgroundNotificationService', () => {
    let service: BackgroundNotificationService;
    let translateServiceMock: TranslateServiceMock;
    let fileDownloadService: FileDownloadServiceMock;
    const httpMock = new HttpClientMock();

    beforeEach(() => {
        translateServiceMock = new TranslateServiceMock();
        fileDownloadService = new FileDownloadServiceMock();
        service = new BackgroundNotificationService(translateServiceMock as any, httpMock as any, fileDownloadService as any);
    });

    it('should create', () => {
        expect(service).toBeTruthy();
    });

    it('should call server to get background messages', () => {
        const data = {
            processId: -457,
            identityId: 45,
            processType: 'GlobalCaseChange',
            statusDate: new Date(),
            statusInfo: '',
            status: 'completed'
        };

        const dataFromServer = [data];
        const readMessageData = [
            {
                identityId: 45,
                processId: -457,
                processName: 'backgroundNotifications.processTypes.globalcasechange',
                status: 'backgroundNotifications.statusType.completed',
                statusDate: data.statusDate,
                statusInfo: '',
                tooltip: 'backgroundNotifications.tooltips.globalcasechange'
            }
        ];

        service.http.get = jest.fn().mockReturnValue(of(dataFromServer));
        service.readMessages$ = jest.fn().mockReturnValue(of(readMessageData));
        service.setProcessIds([1]);
        expect(service.http.get).toHaveBeenCalledWith('api/backgroundProcess/list');
        service.readMessages$().subscribe(
            result => expect(result).toEqual(readMessageData)
        );
    });
    it('should send process name using process subtype', () => {
        const data = {
            processId: -457,
            identityId: 45,
            processType: 'GlobalCaseChange',
            statusDate: new Date(),
            statusInfo: '',
            status: 'completed',
            processSubType: 'Policing'
        };

        const dataFromServer = [data];
        const readMessageData = [
            {
                identityId: 45,
                processId: -457,
                processName: 'backgroundNotifications.processTypes.policing',
                status: 'backgroundNotifications.statusType.completed',
                statusDate: data.statusDate,
                statusInfo: '',
                tooltip: 'backgroundNotifications.tooltips.policing'
            }
        ];

        service.http.get = jest.fn().mockReturnValue(of(dataFromServer));
        service.readMessages$ = jest.fn().mockReturnValue(of(readMessageData));
        service.setProcessIds([1]);
        service.readMessages$().subscribe(
            result => expect(result).toEqual(readMessageData)
        );
    });

    it('delete a notification', () => {
        const data = {
            processId: -457,
            identityId: 45,
            processType: 'GlobalCaseChange',
            statusDate: new Date(),
            statusInfo: '',
            status: 'completed'
        };

        const dataFromServer = [data];
        service.http.post = jest.fn().mockReturnValue(of(dataFromServer));
        service.deleteProcessIds([-457]);
        expect(service.http.post).toHaveBeenCalledWith('api/backgroundProcess/delete', [-457]);
    });

    it('delete all notification', () => {
        service.deleteProcessIds(undefined);
        expect(service.http.post).toHaveBeenCalledWith('api/backgroundProcess/delete', []);
    });

    it('should call file download service - to download cpa -xml', () => {
        service.downloadCpaXmlExport(4);

        expect(fileDownloadService.downloadFile).toHaveBeenCalledWith('api/backgroundProcess/cpaXmlExport?processId=4', null);
    });
});