import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { ChangeDetectorRefMock, HttpClientMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { CaseDetailServiceMock } from '../case-detail.service.mock';
import { DesignElementsMaintenanceComponent } from './design-elements-maintenance/design-elements-maintenance.component';
import { DesignElementsComponent } from './design-elements.component';

describe('DesignElementsComponent', () => {
  let component: DesignElementsComponent;
  let localSettings: LocalSettingsMock;
  let modalService: any;
  let formBuilder: FormBuilder;
  let cdRef: ChangeDetectorRefMock;
  let rootService: RootScopeServiceMock;
  let caseDetailService: CaseDetailServiceMock;
  let notificationServiceMock: NotificationServiceMock;
  let http: HttpClientMock;
  let service: {
    getDesignElements(caseKey: number): any;
    raisePendingChanges(): any;
    raiseHasErrors(): any;
    isAddAnotherChecked: any;
  };
  let shortcutsService: IpxShortcutsServiceMock;
  let destroy$: any;
  beforeEach(() => {
    http = new HttpClientMock();
    service = {
      getDesignElements: jest.fn(),
      raisePendingChanges: jest.fn(),
      raiseHasErrors: jest.fn(),
      isAddAnotherChecked: jest.fn().mockReturnValue(false)
    };
    localSettings = new LocalSettingsMock();
    modalService = new ModalServiceMock();
    formBuilder = new FormBuilder();
    cdRef = new ChangeDetectorRefMock();
    rootService = new RootScopeServiceMock();
    caseDetailService = new CaseDetailServiceMock();
    notificationServiceMock = new NotificationServiceMock();
    shortcutsService = new IpxShortcutsServiceMock();
    destroy$ = of({}).pipe(delay(1000));
    component = new DesignElementsComponent(localSettings as any, service as any, modalService, formBuilder as any, cdRef as any, rootService as any, caseDetailService as any, notificationServiceMock as any, destroy$, shortcutsService as any);
    component.isHosted = false;
    component.topic = {
      hasErrors$: new BehaviorSubject<Boolean>(false),
      setErrors: jest.fn(),
      getErrors: jest.fn(),
      hasChanges: false,
      key: 'designelement',
      title: 'design element',
      params: {
        viewData: {
          caseKey: 123
        }
      }
    } as any;
    component.grid = {
      checkChanges: jest.fn(),
      closeEditedRows: jest.fn(),
      isValid: jest.fn(),
      isDirty: jest.fn(),
      wrapper: {
        data: [
          {
            firmElementCaseRef: '123',
            clientElementCaseRef: '123',
            elementOfficialNo: '123',
            registrationNo: '123',
            noOfViews: 1,
            elementDescription: '567',
            renew: true,
            sequence: 0,
            status: null,
            rowKey: 0
          }, {
            firmElementCaseRef: '1234',
            clientElementCaseRef: '123',
            elementOfficialNo: '123',
            registrationNo: '123',
            noOfViews: 1,
            elementDescription: '567',
            renew: true,
            sequence: 1,
            status: null,
            rowKey: 1
          }
        ]
      },
      rowEditFormGroups: [
        'formgroup1',
        'formgroup2'
      ]
    } as any;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('ngOnInit', () => {
    it('should initialise the column configs correctly', () => {
      component.topic = {
        hasErrors$: new BehaviorSubject<Boolean>(false),
        setErrors: jest.fn(),
        params: {
          viewData: {
            canMaintainCase: true
          }
        }
      } as any;

      spyOn(component.topic, 'setErrors').and.returnValue(false);
      component.ngOnInit();
      const columnFields = component.gridOptions.columns.map(col => col.field);
      component.topic.hasErrors$.subscribe((err) => { expect(err).toBeFalsy(); });
      expect(component.topic.hasChanges).toBe(false);
      expect(columnFields).toEqual(['firmElementCaseRef', 'clientElementCaseRef', 'elementOfficialNo', 'registrationNo', 'noOfViews', 'elementDescription', 'renew', 'stopRenewDate']);
    });

    it('should initialize shortcuts', () => {
      component.ngOnInit();
      expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.ADD]);
    });

    it('should call add on event if hosted', fakeAsync(() => {
      component.grid.onAdd = jest.fn();
      component.isHosted = true;
      shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.ADD;
      component.ngOnInit();
      tick(shortcutsService.interval);

      expect(component.grid.onAdd).toHaveBeenCalled();
    }));

    it('should call the service on $read', () => {
      component.ngOnInit();
      const queryParams = 'test';
      component.gridOptions.read$(queryParams as any);
      expect(service.getDesignElements).toHaveBeenCalledWith(123, queryParams);
    });

    it('should having correct grid row maintenance settings ', () => {
      component.isHosted = true;
      component.topic.params = {
        viewData: {
          canMaintainCase: true
        }
      };
      component.ngOnInit();
      const queryParams = 'test';
      component.gridOptions.read$(queryParams as any);
      expect(component.gridOptions.rowMaintenance).toEqual({ canEdit: true, canDelete: true, rowEditKeyField: 'rowKey' });
    });

    describe('girdHandlers', () => {
      it('should handle row add edit correctly', () => {
        modalService.openModal.mockReturnValue({
          content: {
            onClose$: new BehaviorSubject(true)
          }
        });
        component.updateChangeStatus = jest.fn();
        component.gridOptions = { rowMaintenance: { rowEditKeyField: 'rowKey' } } as any;
        const data = {
          dataItem: {
            firmElementCaseRef: '123',
            clientElementCaseRef: '123',
            elementOfficialNo: '123',
            registrationNo: '123',
            noOfViews: 1,
            elementDescription: '567',
            renew: true,
            sequence: 0,
            status: null
          }
        };
        component.onRowAddedOrEdited(data as any);
        expect(component.gridOptions.rowMaintenance.rowEditKeyField).toEqual('rowKey');
        expect(modalService.openModal).toHaveBeenCalledWith(DesignElementsMaintenanceComponent,
          {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
              dataItem: data.dataItem,
              isAdding: false,
              grid: component.grid,
              caseKey: 123,
              rowIndex: undefined
            }
          });
      });

      it('should update status correctly ', () => {
        component.grid = {
          checkChanges: jest.fn(),
          isValid: jest.fn(),
          isDirty: jest.fn(),
          wrapper: {
            data: [
              {
                firmElementCaseRef: '123',
                clientElementCaseRef: '123',
                elementOfficialNo: '123',
                registrationNo: '123',
                noOfViews: 1,
                elementDescription: '567',
                renew: true,
                sequence: 0,
                status: 'A'
              }, {
                firmElementCaseRef: '1234',
                clientElementCaseRef: '123',
                elementOfficialNo: '123',
                registrationNo: '123',
                noOfViews: 1,
                elementDescription: '567',
                renew: true,
                sequence: 1,
                status: 'E'
              }
            ]
          }
        } as any;
        jest.spyOn(service, 'raisePendingChanges');
        jest.spyOn(service, 'raiseHasErrors');
        component.updateChangeStatus();
        expect(component.grid.checkChanges).toHaveBeenCalled();
        expect(component.topic.hasChanges).toBeTruthy();
        expect(service.raisePendingChanges).toHaveBeenCalled();
        expect(service.raiseHasErrors).toHaveBeenCalled();
      });

      it('should throw validation errors', () => {
        const errors: any = [{
          warningFlag: true,
          topic: 'designelement',
          field: 'renew',
          id: 1
        }];
        component.setErrors(errors);
        expect(notificationServiceMock.alert).toHaveBeenCalled();
      });
    });
  });

  describe('paging', () => {
    it('should  call onCloseModal', () => {
      component.ngOnInit();
      modalService.openModal.mockReturnValue({
        content: {
          onClose$: new BehaviorSubject(true)
        }
      });
      component.grid = {
        wrapper: {
          data: [
            {
              firmElementCaseRef: '123',
              clientElementCaseRef: '123',
              elementOfficialNo: '123',
              registrationNo: '123',
              noOfViews: 1,
              elementDescription: '567',
              renew: true,
              sequence: 0,
              status: 'A'
            }, {
              firmElementCaseRef: '1234',
              clientElementCaseRef: '123',
              elementOfficialNo: '123',
              registrationNo: '123',
              noOfViews: 1,
              elementDescription: '567',
              renew: true,
              sequence: 1,
              status: 'E'
            }
          ]
        }
      } as any;

      component.gridOptions = {} as any;
      const data = {
        dataItem: {
          firmElementCaseRef: '123-Added',
          clientElementCaseRef: '123',
          elementOfficialNo: '123',
          registrationNo: '123',
          noOfViews: 1,
          elementDescription: '567',
          renew: true,
          sequence: 3,
          status: 'A',
          rowKey: 3
        }
      };
      jest.spyOn(component, 'onCloseModal');
      component.onRowAddedOrEdited(data as any);
      expect(component.onCloseModal).toHaveBeenCalled();
    });

    it('should call onCloseModal for select page mehtod if add another checked with second page index', () => {
      component.ngOnInit();
      modalService.openModal.mockReturnValue({
        content: {
          onClose$: new BehaviorSubject(true)
        }
      });

      component.grid = {
        checkChanges: jest.fn(),
        closeEditedRows: jest.fn(),
        isValid: jest.fn().mockReturnValue(true),
        isDirty: jest.fn().mockReturnValue(true),
        wrapper: {
          data: [
            {
              firmElementCaseRef: '123',
              clientElementCaseRef: '123',
              elementOfficialNo: '123',
              registrationNo: '123',
              noOfViews: 1,
              elementDescription: '567',
              renew: true,
              sequence: 0,
              status: 'A'
            }, {
              firmElementCaseRef: '1234',
              clientElementCaseRef: '123',
              elementOfficialNo: '123',
              registrationNo: '123',
              noOfViews: 1,
              elementDescription: '567',
              renew: true,
              sequence: 1,
              status: 'E'
            }
          ]
        }
      } as any;
      component.skip = 10;
      component.gridOptions = { _selectPage: jest.fn() } as any;
      const data = {
        dataItem: {
          firmElementCaseRef: '123-Added',
          clientElementCaseRef: '123',
          elementOfficialNo: '123',
          registrationNo: '123',
          noOfViews: 1,
          elementDescription: '567',
          renew: true,
          sequence: 3,
          status: 'A',
          rowKey: 3,
          images: { key: 1, value: 'image1' }
        }
      };
      jest.spyOn(component, 'updateChangeStatus');
      service.isAddAnotherChecked = {
        getValue: jest.fn().mockReturnValue(false)
      };
      component.onCloseModal(true, data);
      expect(component.updateChangeStatus).toHaveBeenCalled();
      expect(service.isAddAnotherChecked.getValue).toHaveBeenCalled();
      expect(component.grid.closeEditedRows).toHaveBeenCalledWith(10);
    });
  });
});
