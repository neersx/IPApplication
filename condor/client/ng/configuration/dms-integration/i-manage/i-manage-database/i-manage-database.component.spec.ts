import { DmsServiceMock } from 'common/case-name/dms/dms.service.mock';
import { DmsIntegrationServiceMock } from 'configuration/dms-integration/dms-integration.service.mock';
import { ChangeDetectorRefMock, EventEmitterMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject } from 'rxjs';
import { IManageDatabaseComponent } from './i-manage-database.component';
import { IManageDatabaseModelComponent } from './i-manage-database/i-manage-database-model.component';

describe('IManageDatabaseComponent', () => {
  let component: IManageDatabaseComponent;
  let modalService: ModalServiceMock;
  let cdRef: ChangeDetectorRefMock;
  let service: DmsIntegrationServiceMock;
  let dmsService: DmsServiceMock;
  let translate: TranslateServiceMock;
  let notificationService: NotificationServiceMock;
  beforeEach(() => {
    modalService = new ModalServiceMock();
    cdRef = new ChangeDetectorRefMock();
    service = new DmsIntegrationServiceMock();
    translate = new TranslateServiceMock();
    notificationService = new NotificationServiceMock();
    dmsService = new DmsServiceMock();
    component = new IManageDatabaseComponent(modalService as any, cdRef as any, service as any, translate as any, notificationService as any, dmsService as any);
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

    component.ngOnInit();

    return component;
  });

  describe('ngOnDestroy', () => {
    it('should disconnect from messagebroker on destroy', () => {
      component.ngOnDestroy();

      expect(dmsService.disconnectBindings).toHaveBeenCalled();
    });
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should get database rows', () => {
    expect(component.databases.length).toBe(1);
  });

  it('should having correct grid row maintenance settings ', () => {
    expect(component.gridOptions.rowMaintenance).toEqual({ canEdit: true, canDelete: true, rowEditKeyField: 'siteDbId' });
  });

  it('should handle row add correctly', () => {
    modalService.openModal.mockReturnValue({
      content: {
        onClose$: new BehaviorSubject(true)
      }
    });
    component.gridOptions.formGroup = { dirty: false } as any;
    component.grid = { rowCancelHandler: jest.fn() } as any;
    (component.topic.setCount as any) = new EventEmitterMock<number>();
    const data = {
      dataItem: {
        siteDbId: 0,
        database: 'database2',
        server: 'server2',
        integrationType: 'Demo',
        loginType: 'TurstedLogin',
        customerId: null
      },
      rowIndex: 0
    };
    component.onRowAddedOrEdited(data as any, true);

    expect(component.gridOptions.rowMaintenance.rowEditKeyField).toEqual('siteDbId');
    expect(modalService.openModal).toHaveBeenCalledWith(IManageDatabaseModelComponent,
      {
        animated: false,
        backdrop: 'static',
        class: 'modal-xl',
        initialState: {
          isAdding: true,
          grid: component.grid,
          dataItem: data.dataItem,
          rowIndex: data.rowIndex,
          topic: component.topic
        }
      });
  });

  it('should update status correctly ', () => {
    component.grid = {
      checkChanges: jest.fn(),
      wrapper: {
        data: [
          {
            siteDbId: 0,
            database: 'database1',
            server: 'server1',
            integrationType: 'Demo',
            loginType: 'TurstedLogin',
            customerId: null,
            status: 'A'
          }, {
            siteDbId: 1,
            database: 'database2',
            server: 'server2',
            integrationType: 'Demo',
            loginType: 'TurstedLogin',
            customerId: null
          }
        ]
      }
    } as any;
    (component.topic.setCount as any) = new EventEmitterMock<number>();
    component.updateChangeStatus();
    component.topic.hasErrors$.subscribe((err) => { expect(err).toBeFalsy(); });
    expect(component.grid.checkChanges).toHaveBeenCalled();
    expect(component.gridOptions.rowMaintenance).toEqual({ canEdit: true, canDelete: true, rowEditKeyField: 'siteDbId' });
  });

  describe('getManifest', () => {
    it('should call getManifest on the service', () => {
      const dataItem = {
        test: 'test'
      };

      component.getManifest(dataItem);

      expect(service.getManifest).toHaveBeenCalledWith(dataItem);
    });
  });
});
