import { AppContextServiceMock } from 'core/app-context.service.mock';
import { HttpClientMock, NgZoneMock } from 'mocks';
import { of } from 'rxjs/internal/observable/of';
import { DmsService } from './dms.service';

describe('Service: RelatedCases', () => {
    let http: HttpClientMock;
    let ctx: AppContextServiceMock;
    let service: DmsService;
    let zone: NgZoneMock;
    let messageBroker: {
        subscribe: jest.Mock,
        disconnectBindings: jest.Mock,
        connect: jest.Mock,
        getConnectionId: jest.Mock
    };

    let winRef: any;
    beforeEach(() => {
        http = new HttpClientMock();
        ctx = new AppContextServiceMock();
        zone = new NgZoneMock();
        winRef = { nativeWindow: { open: jest.fn() } };
        messageBroker = {
            subscribe: jest.fn(),
            disconnectBindings: jest.fn(),
            connect: jest.fn(),
            getConnectionId: jest.fn().mockReturnValue('10')
        };
        service = new DmsService(http as any, messageBroker as any, zone as any, winRef, ctx as any);
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });
    describe('getDmsFolders$', () => {
        it('should call dms folder api and process authentication flag', () => {
            http.get.mockReturnValueOnce(of({ isAuthRequired: true }));

            service.getDmsFolders$({ callerType: 'CaseView' }, 111);

            expect(http.get).toHaveBeenCalledWith('api/case/111/document-management/folders');
            expect(service.isOAuth2Authenticated$.value).toEqual(true);
        });
    });
    describe('getDmsDocuments$', () => {
        it('should call dms document api and process authentication flag', () => {
            const queryParams = {
                skip: 0,
                take: 20
            };
            http.get.mockReturnValueOnce(of({ isAuthRequired: true }));
            service.getDmsDocuments$(111, '222', queryParams, 'folderType');
            expect(http.get).toHaveBeenCalledWith('api/document-management/documents/111-222', {
                params: {
                    params: JSON.stringify(queryParams),
                    options: JSON.stringify({ folderType: 'folderType' })
                }
            });
            expect(service.isOAuth2Authenticated$.value).toEqual(true);
        });
    });
    describe('getDmsDocumentDetails$', () => {
        it('should call getDmsDocumentDetails api and process authentication flag', () => {
            http.get.mockReturnValueOnce(of({ isAuthRequired: true }));
            service.getDmsDocumentDetails$(111, '222');
            expect(http.get).toHaveBeenCalledWith('api/document-management/document/111-222');
            expect(service.isOAuth2Authenticated$.value).toEqual(true);
        });
    });
});
