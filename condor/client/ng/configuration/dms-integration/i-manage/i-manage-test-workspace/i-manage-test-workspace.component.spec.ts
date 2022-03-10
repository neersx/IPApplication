import { NgForm } from '@angular/forms';
import { DmsIntegrationServiceMock } from 'configuration/dms-integration/dms-integration.service.mock';
import { WorkspaceType } from 'configuration/dms-integration/dms-models';
import { ChangeDetectorRefMock } from 'mocks';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subscription } from 'rxjs';
import { IManageTestWorkspaceComponent } from './i-manage-test-workspace.component';

describe('IManageTestCaseDocumentComponent', () => {
  let component: IManageTestWorkspaceComponent;
  let modalRef: BsModalRef;
  let cdr: ChangeDetectorRefMock;
  let service: DmsIntegrationServiceMock;

  beforeEach(() => {
    cdr = new ChangeDetectorRefMock();
    service = new DmsIntegrationServiceMock();
    modalRef = new BsModalRef();
    component = new IManageTestWorkspaceComponent(service as any, cdr as any, modalRef as any);
    modalRef.hide = jest.fn();
    service.getCredentials.mockReturnValue({ username: 'test', password: 'pwd' });
    service.getRequiresCredentials.mockReturnValue({});
    component.form = new NgForm(null, null);
    component.iManageSettingData = {
      iManageSettings: {
        Databases: [
          {
            siteDbId: 10,
            database: 'database1',
            server: 'server1',
            integrationType: 'iManage Work API V2',
            loginType: 'TurstedLogin',
            customerId: 1
          }
        ]
      },
      username: null,
      password: null
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initializes username & password', () => {
    component.ngOnInit();
    expect(service.getCredentials).toHaveBeenCalled();
    expect(service.getRequiresCredentials).toHaveBeenCalledWith(component.iManageSettingData.iManageSettings.Databases);
    expect(component.formData.username).toEqual('test');
    expect(component.formData.password).toEqual('pwd');
  });

  it('should call the testCaseWorkspace$ with appropriate parameters', () => {
    component.workspaceType = WorkspaceType.Case;
    component.formData = { caseIrn: { key: 1 } };
    component.runTestWorkspace();
    service.testCaseWorkspace$().then((resp) => {
      expect(resp).toEqual([]);
      expect(component.results).toEqual(resp);
      expect(component.showLoader).toBeFalsy();
    });
  });

  it('should call the testNameWorkspace$ with appropriate parameters', () => {
    component.workspaceType = WorkspaceType.Name;
    component.formData = { name: { key: 1 } };
    component.runTestWorkspace();
    service.testNameWorkspace$().then((resp) => {
      expect(resp).toEqual([]);
      expect(component.results).toEqual(resp);
      expect(component.showLoader).toBeFalsy();
    });
  });

  it('should cancel properly', () => {
    component.onClose$.next = jest.fn() as any;
    component.cancel({} as any);
    expect(component.onClose$.next).toHaveBeenCalledWith(null);
    expect(modalRef.hide).toHaveBeenCalled();
  });

  it('unsubscribes on destroy', () => {
    const unsubscribe = jest.fn();
    component.subscription = new Subscription(unsubscribe);
    component.ngOnDestroy();
    expect(unsubscribe).toHaveBeenCalled();
  });
});
