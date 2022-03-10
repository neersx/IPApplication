import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder, Validators } from '@angular/forms';
import { DmsIntegrationServiceMock } from 'configuration/dms-integration/dms-integration.service.mock';
import { ChangeDetectorRefMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject } from 'rxjs';
import { IManageDatabaseModelComponent } from './i-manage-database-model.component';

describe('IManageDatabaseComponent', () => {
  let component: IManageDatabaseModelComponent;
  let modalService: ModalServiceMock;
  let cdr: ChangeDetectorRefMock;
  let notificationService: NotificationServiceMock;
  let service: DmsIntegrationServiceMock;

  beforeEach(() => {
    modalService = new ModalServiceMock();
    notificationService = new NotificationServiceMock();
    cdr = new ChangeDetectorRefMock();
    service = new DmsIntegrationServiceMock();
    component = new IManageDatabaseModelComponent(new FormBuilder(), modalService as any, notificationService as any, cdr as any, service as any);

    component.formGroup = {
      dirty: true,
      reset: jest.fn(),
      controls: {
        integrationType: {
          valueChanges: new BehaviorSubject('iManage Work API V2')
        },
        loginType: {
          valueChanges: new BehaviorSubject('UsernameWithImpersonation'),
          updateValueAndValidity: jest.fn(),
          setValue: jest.fn()
        },
        server: {
          valueChanges: new BehaviorSubject('Server')
        },
        customerId: {
          setValidators: jest.fn(),
          setValue: jest.fn()
        },
        password: {
          setValidators: jest.fn(),
          setValue: jest.fn()
        },
        clientId: {
          setValidators: jest.fn(),
          setValue: jest.fn(),
          markAsTouched: jest.fn(),
          markAsDirty: jest.fn(),
          clearValidators: jest.fn(),
          updateValueAndValidity: jest.fn()
        },
        clientSecret: {
          setValidators: jest.fn(),
          setValue: jest.fn(),
          markAsTouched: jest.fn(),
          markAsDirty: jest.fn(),
          clearValidators: jest.fn(),
          updateValueAndValidity: jest.fn()
        }
      },
      value: {
        databaseId: 1,
        database: 'database2',
        server: 'server2',
        integrationType: 'iManage Work API V2',
        loginType: 'UsernameWithImpersonation',
        customerId: null
      }
    } as any;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should set correct status', () => {
    component.ngAfterViewInit();
    expect(component.showPassword$.getValue()).toBeTruthy();
    expect(component.showCustomerId$.getValue()).toBeTruthy();
    expect(component.formGroup.controls.customerId.setValidators).toHaveBeenCalledWith([Validators.required]);
    expect(component.formGroup.controls.password.setValidators).toHaveBeenCalledWith([Validators.required]);
  });

  it('should generate a client id', () => {
    component.generateClientId();

    expect(component.formGroup.controls.clientId.setValue).toHaveBeenCalled();
    expect(cdr.markForCheck).toHaveBeenCalled();
  });

  it('should generate a client secret', () => {
    component.generateClientSecret();

    expect(component.formGroup.controls.clientSecret.setValue).toHaveBeenCalled();
    expect(cdr.markForCheck).toHaveBeenCalled();
  });

  it('should update to correct login types list if IManage', () => {
    const integrationType = 'iManage Work API V2';
    component.updateLoginTypes(integrationType);

    expect(component.shownLoginTypes).toEqual(component.iManageLoginTypes);
    expect(component.showWorkApiV2$.getValue()).toBeTruthy();
  });

  it('should update to correct login types list if not IManage', () => {
    const integrationType = 'other';
    component.updateLoginTypes(integrationType);

    expect(component.shownLoginTypes).toEqual(component.loginTypes);
    expect(component.showWorkApiV2$.getValue()).toBeFalsy();
  });

  it('should set customerId to null or 1', () => {
    component.integrationTypeChange('iManage Work API V2');
    expect(component.formGroup.controls.customerId.setValue).toHaveBeenCalledWith(1);
    component.integrationTypeChange('demo');
    expect(component.formGroup.controls.customerId.setValue).toHaveBeenCalledWith(null);
  });

  it('should set password to null or 1', () => {
    component.loginTypeChange('UsernameWithImpersonation');
    expect(component.formGroup.controls.password.setValue).toHaveBeenCalledTimes(0);
    component.loginTypeChange('InprotechUsernameWithImpersonation');
    expect(component.formGroup.controls.password.setValue).toHaveBeenCalledTimes(0);
    component.loginTypeChange('login');
    expect(component.formGroup.controls.password.setValue).toHaveBeenCalledWith(null);
  });

  it('should cancel properly', () => {
    notificationService.openDiscardModal.mockReturnValue({ content: { confirmed$: new BehaviorSubject('') } });
    component.cancel({} as any);
    expect(notificationService.openDiscardModal).toHaveBeenCalled();
    expect(component.formGroup.reset).toHaveBeenCalledTimes(0);
  });

  it('should create formGroup Correctly ', () => {
    const item = {
      siteDbId: 0,
      database: 'database',
      server: 'http://server.server',
      accessTokenUrl: 'http://server.server/auth/auth2/token',
      authUrl: 'http://server.server/auth/auth2/authorize',
      callbackUrl: 'undefined/dms/imanage/auth/redirect',
      integrationType: 'type',
      clientId: null,
      clientSecret: null,
      loginType: 'login',
      customerId: null,
      password: null,
      status: 'add'
    };
    component.topic = {
      key: 'database',
      title: 'database',
      hasErrors$: new BehaviorSubject<boolean>(false),
      setErrors: jest.fn(),
      getErrors: jest.fn(),
      params: {
        viewData: {
          imanageSettings: {
            databases: [
              {
                siteDbId: 10,
                database: 'database1',
                server: 'server1',
                integrationType: 'iManage Work API V2',
                loginType: 'TurstedLogin',
                customerId: 1
              }
            ]
          }
        }
      }
    };
    component.dataItem = item;
    const fg = component.createFormGroup(item, component.topic);
    expect(Object.keys(fg.controls).length).toEqual(13);
    expect(fg.value).toEqual(item);
  });

  describe('apply', () => {
    it('should close modal if dirty and not invalid', fakeAsync(() => {
      component.formGroup = { ...component.formGroup, dirty: true, status: 'not invalid', setErrors: jest.fn() } as any;
      (component as any).sbsModalRef = {
        hide: jest.fn()
      } as any;
      component.onClose$.next = jest.fn() as any;
      component.apply(null);
      tick(100);
      expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
      expect(component.onClose$.next).toHaveBeenCalledWith({ success: true, formGroup: component.formGroup });
    }));

    it('should close modal if clean and not invalid', () => {
      component.formGroup = { dirty: false, status: 'not invalid' } as any;
      (component as any).sbsModalRef = {
        hide: jest.fn()
      } as any;
      component.onClose$.next = jest.fn() as any;

      component.apply(null);

      expect((component as any).sbsModalRef.hide).not.toHaveBeenCalled();
      expect(component.onClose$.next).not.toHaveBeenCalledWith(true);
    });

    it('should close modal if dirty and Invalid', () => {
      component.formGroup = { dirty: true, status: 'INVALID' } as any;
      (component as any).sbsModalRef = {
        hide: jest.fn()
      } as any;
      component.onClose$.next = jest.fn() as any;

      component.apply(null);

      expect((component as any).sbsModalRef.hide).not.toHaveBeenCalled();
      expect(component.onClose$.next).not.toHaveBeenCalledWith(true);
    });
  });
});
