import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { MaintainRecordalTypeComponent } from './maintain-recordal-type.component';

describe('MaintainRecordalTypeComponent', () => {
  let component: MaintainRecordalTypeComponent;
  const recordalTypeServiceMock = {
    deleteRecordalType: jest.fn().mockReturnValue(of({})),
    isAddAnotherChecked: new BehaviorSubject(false)
  };
  let notificationService: NotificationServiceMock;
  let changeDetectorRef: ChangeDetectorRefMock;
  let ipxNotificationService: IpxNotificationServiceMock;
  let bsModal: BsModalRefMock;
  let translate: TranslateServiceMock;
  let modalService: ModalServiceMock;
  let fb: FormBuilder;

  beforeEach(() => {
    notificationService = new NotificationServiceMock();
    changeDetectorRef = new ChangeDetectorRefMock();
    ipxNotificationService = new IpxNotificationServiceMock();
    bsModal = new BsModalRefMock();
    modalService = new ModalServiceMock();
    translate = new TranslateServiceMock();
    fb = new FormBuilder();

    component = new MaintainRecordalTypeComponent(recordalTypeServiceMock as any, changeDetectorRef as any,
      ipxNotificationService as any, bsModal as any,
      notificationService as any, translate as any,
      modalService as any, fb as any);

    component.dataItem = { id: 1, status: 'A' };
    component.viewData = {
      canAdd: true,
      canEdit: true,
      canDelete: true
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize component', () => {
    jest.spyOn(component, 'createFormGroup');
    jest.spyOn(component, 'buildGridOptions');
    component.ngOnInit();
    expect(component.isSaveDisabled).toBeTruthy();
    expect(component.createFormGroup).toBeCalled();
    expect(component.buildGridOptions).toBeCalled();
  });

  it('should set formData', () => {
    const data = {
      recordalType: 1,
      recordalEvent: 'Abc',
      recordalAction: '',
      requestEvent: 'Sf',
      requestAction: ''
    };
    component.form = { patchValue: jest.fn() };
    component.setFormData(data);
    expect(component.form.patchValue).toBeCalledWith(data);
  });

  it('should create new formGroup', () => {
    component.createFormGroup();
    expect(component.form).not.toBeNull();
  });

  it('should submit formData', () => {
    const data = {
      recordalType: 1,
      recordalEvent: 'Abc',
      recordalAction: '',
      requestEvent: 'Sf',
      requestAction: ''
    };
    component.form = {
      value: data,
      valid: true
    };
    component.grid = {
      wrapper: { data: [] }
    };
    component.submit();
    expect(component.form).not.toBeNull();
  });

  it('should pass data onCloseModal', () => {
    modalService.openModal.mockReturnValue({
      content: {
        onClose$: new BehaviorSubject(true)
      }
    });

    component.form = {
      markAsDirty: jest.fn(),
      valid: true
    };

    component.grid = {
      addRow: jest.fn(),
      closeEditedRows: jest.fn(),
      isValid: jest.fn().mockReturnValue(true),
      isDirty: jest.fn().mockReturnValue(true),
      wrapper: {
        data: [
          {
            id: 123,
            recordalType: 1,
            recordalEvent: 'Abc',
            recordalAction: 'J',
            requestEvent: 'Sf',
            requestAction: 'D',
            status: 'A'
          }, {
            id: 3,
            recordalType: 19,
            recordalEvent: 'asd',
            recordalAction: 'A',
            requestEvent: 'HJ',
            requestAction: 'D',
            status: 'E'
          }
        ]
      }
    } as any;
    component.gridOptions = { maintainFormGroup$: new BehaviorSubject(true) } as any;
    const data = {
      dataItem: {
        recordalType: 19,
        recordalEvent: 'asd',
        recordalAction: 'A',
        requestEvent: 'HJ',
        requestAction: 'D',
        status: 'E'
      }
    };

    component.onCloseModal({ success: true }, data);
    expect(component.form.markAsDirty).toHaveBeenCalled();
    expect(component.isSaveDisabled).toBeFalsy();
  });

  it('should delete a row', () => {
    component.form = {
      markAsDirty: jest.fn(),
      valid: true
    };
    component.onRowDeleted();
    expect(component.form.markAsDirty).toHaveBeenCalled();
    expect(component.isSaveDisabled).toBeFalsy();
  });

  it('should revert the delete and edit row', () => {
    component.form = {
      markAsDirty: jest.fn(),
      valid: true
    };

    component.grid = {
      checkChanges: jest.fn(),
      closeEditedRows: jest.fn(),
      isValid: jest.fn().mockReturnValue(true),
      isDirty: jest.fn().mockReturnValue(true),
      wrapper: {
        data: []
      }
    } as any;
    jest.spyOn(component, 'getEditedRows');
    component.cancelEdit();
    expect(component.grid.isValid).toBeCalled();
    expect(component.grid.checkChanges).toHaveBeenCalled();
    expect(component.isSaveDisabled).toBeTruthy();
    expect(component.getEditedRows).toHaveBeenCalled();
  });

});
