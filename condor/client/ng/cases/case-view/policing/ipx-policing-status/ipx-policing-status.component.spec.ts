import { ChangeDetectorRefMock, NgZoneMock, NotificationServiceMock } from 'mocks';
import { IpxPolicingStatusComponent } from './ipx-policing-status.component';

describe('IpxPolicingStatusComponent', () => {
  let component: IpxPolicingStatusComponent;
  let zone: NgZoneMock;
  let messageBroker: {
    subscribe: jest.Mock,
    disconnectBindings: jest.Mock,
    connect: jest.Mock
  };
  let policingService: {
    policingCompleted: {
      subscribe: jest.Mock
    }
  };
  let bus: {
    channel: jest.Mock
  };
  let notificationService: NotificationServiceMock;
  let cdr: ChangeDetectorRefMock;

  beforeEach(() => {
    zone = new NgZoneMock();
    messageBroker = {
      subscribe: jest.fn(),
      disconnectBindings: jest.fn(),
      connect: jest.fn()
    };
    policingService = {
      policingCompleted: {
        subscribe: jest.fn()
      }
    };
    bus = {
      channel: jest.fn().mockReturnValue({ broadcast: jest.fn() })
    };
    notificationService = new NotificationServiceMock();
    cdr = new ChangeDetectorRefMock();
    component = new IpxPolicingStatusComponent(zone as any, messageBroker as any, cdr as any, policingService as any, bus as any, notificationService as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('ngOnDestroy', () => {
    it('should disconnect bindings', () => {
      component.subscription = { unsubscribe: jest.fn() };
      component.ngOnDestroy();

      expect(messageBroker.disconnectBindings).toHaveBeenCalled();
      expect(component.subscription.unsubscribe).toHaveBeenCalled();
    });
  });

  describe('ngOnInit', () => {
    it('should set up bindings appropriately', () => {
      component.caseKey = 100;

      component.ngOnInit();

      expect(messageBroker.subscribe).toHaveBeenCalledWith('policing.change.100', expect.anything());
      expect(messageBroker.connect).toHaveBeenCalled();
    });
  });
});
