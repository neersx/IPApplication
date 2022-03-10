import { HttpClientMock, NgZoneMock, NotificationServiceMock } from 'mocks';
import { GraphIntegrationService } from './graph-integration.service';

describe('GraphIntegrationService', () => {
    let service: GraphIntegrationService;
    let http: HttpClientMock;
    let zone: NgZoneMock;
    let messageBroker: {
        subscribe: jest.Mock,
        disconnectBindings: jest.Mock,
        connect: jest.Mock,
        getConnectionId: jest.Mock
    };

    let winRef: any;
    let notificationServiceMock: NotificationServiceMock;
    let translateMock: any;

    beforeEach(() => {
        http = new HttpClientMock();
        zone = new NgZoneMock();
        winRef = { nativeWindow: { open: jest.fn() } };
        translateMock = { instant: jest.fn() };
        messageBroker = {
            subscribe: jest.fn(),
            disconnectBindings: jest.fn(),
            connect: jest.fn(),
            getConnectionId: jest.fn().mockReturnValue('10')
        };
        notificationServiceMock = new NotificationServiceMock();

        service = new GraphIntegrationService(messageBroker as any, winRef, zone as any, notificationServiceMock as any, translateMock);
    });

    it('should create', () => {
        expect(service).toBeTruthy();
    });

    it('verify loginGraph', () => {
        const dataItem = { identityId: 45, processId: 11 };
        service.login(dataItem);
        expect(messageBroker.subscribe).toHaveBeenCalled();
        expect(messageBroker.connect).toHaveBeenCalled();
    });

});