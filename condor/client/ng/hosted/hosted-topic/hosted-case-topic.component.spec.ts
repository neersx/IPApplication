import { CaseDetailServiceMock } from 'cases/case-view/case-detail.service.mock';
import { ChecklistHostComponent } from 'cases/case-view/checklists/checklist-model';
import { NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { of } from 'rxjs';
import { HostedCaseTopicComponent } from './hosted-case-topic.component';

describe('HostedCaseTopicComponent', () => {
  let component: HostedCaseTopicComponent;
  let caseDetailService: CaseDetailServiceMock;
  let notificationService: NotificationServiceMock;
  let wpMessageService: WindowParentMessagingServiceMock;
  let policingService: {
    policeBatch: jest.Mock
  };
  let pingService: {
    ping: jest.Mock
  };
  let modalService: ModalServiceMock;
  beforeEach(() => {
    caseDetailService = new CaseDetailServiceMock();
    notificationService = new NotificationServiceMock();
    modalService = new ModalServiceMock();
    wpMessageService = new WindowParentMessagingServiceMock();
    policingService = {
      policeBatch: jest.fn()
    };

    pingService = {
      ping: jest.fn().mockReturnValue(Promise.resolve())
    };
    component = new HostedCaseTopicComponent(caseDetailService as any, notificationService as any, wpMessageService as any, policingService as any, pingService as any, modalService as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should fetch isPoliceImmediatly before save', () => {
    component.hostId = 'actionHost';
    component.componentRef = { getChanges: () => { return { action: '1001' }; }, topic: { key: 'action' } };
    component.topic = {
      params: {
        viewData: { caseKey: '1001' }
      }
    } as any;
    component.saveChanges = jest.fn();
    component.save(null);
    expect(wpMessageService.postRequestForData).toHaveBeenCalledWith('isPoliceImmediately', 'actionHost', expect.anything(), expect.anything());
  });
  it('should post', () => {
    component.hostId = 'actionHost';
    component.topic = {
      params: {
        viewData: { caseKey: '1001' }
      }
    } as any;
    component.componentRef = { getChanges: () => { return { action: '1001' }; } };
    caseDetailService.updateCaseDetails$ = jest.fn();
    caseDetailService.updateCaseDetails$.mockReturnValue(of({ status: 'success' }));
    component.saveChanges(true);
    pingService.ping().then(() => {
      expect(caseDetailService.updateCaseDetails$).toHaveBeenCalledWith({ caseKey: '1001', forceUpdate: false, isPoliceImmediately: true, program: '', topics: { action: '1001' } });
      expect(notificationService.success).toHaveBeenCalled();
      expect(caseDetailService.hasPendingChanges$.getValue()).toBeFalsy();
      expect(caseDetailService.resetChanges$.getValue()).toBeTruthy();
    });
  });
  it('should hide action buttons for DMS', () => {
    component.hostId = 'caseDMSHost';
    component.topic = {
      params: {
        viewData: { caseKey: '1001', hostId: 'caseDMSHost' }
      }
    } as any;
    component.ngOnInit();
    expect(component.showHeaderBar).toBeFalsy();
  });
  it('should show action buttons for checklist when maintenance is allowed', () => {
    component.hostId = ChecklistHostComponent.ChecklistHost;
    component.topic = {
      params: {
        viewData: { caseKey: '1001', hostId: ChecklistHostComponent.ChecklistHost, canMaintainCase: true }
      }
    } as any;
    component.ngOnInit();
    expect(component.showHeaderBar).toBeTruthy();
  });

  it('should validate before save', () => {
    component.hostId = ChecklistHostComponent.ChecklistHost;
    component.componentRef = { isValid: () => { return false; }, topic: { key: 'checklist' } };
    component.topic = {
      params: {
        viewData: { caseKey: '1001' }
      }
    } as any;
    component.saveChanges = jest.fn();
    component.save(null);
    expect(component.saveChanges).toHaveBeenCalledTimes(0);
  });
});
