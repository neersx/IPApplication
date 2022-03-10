import { ChangeDetectorRefMock } from 'mocks';
import { Observable } from 'rxjs';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { CaseListPicklistComponent } from './case-list-picklist.component';

describe('CaseListPicklistComponent', () => {
  let component: CaseListPicklistComponent;
  const picklistMaintenanceServiceMock = {
    modalStates$: {
      getValue: () => {
        return {
          canAdd: true
        };
      }
    },
    maintenanceMetaData$: { getValue: jest.fn() }
  };
  const caselistPicklistServiceMock = {};
  const cdrMock = new ChangeDetectorRefMock();
  const modalRef = {
    content: {
      selectedRow$: new Observable(),
      onClose$: new Observable()
    }
  };
  const picklistModalServiceMock = {
    openModal: jest.fn().mockReturnValue(modalRef)
  };
  const typeAheadConfigProviderMock = { resolve: jest.fn() };

  beforeEach(() => {
    component = new CaseListPicklistComponent(
      picklistMaintenanceServiceMock as any,
      caselistPicklistServiceMock as any,
      cdrMock as any,
      picklistModalServiceMock as any,
      typeAheadConfigProviderMock as any
    );

    component._caseGrid = new IpxKendoGridComponent(null, null, null, null, null, null);
    component.entry = {
      key: null,
      value: null,
      description: null,
      primeCase: null,
      caseKeys: new Array<number>(),
      newlyAddedCaseKeys: new Array<number>()
    };
    component.ngOnInit();

  });

  it('should create', () => {
    expect(component).toBeDefined();
  });

  it('validate ngOnInit', () => {
    component.entry = {
      caseKeys: [11, 3],
      value: 'test 1',
      description: 'list desc',
      primeCase: 'primecase123',
      newlyAddedCaseKeys: new Array<number>()
    };
    component.ngOnInit();
    expect(component.form.value.value).toEqual('test 1');
    expect(component.form.value.description).toEqual('list desc');
    expect(component.form.value.primeCase).toEqual('primecase123');
  });

  it('verify validate method', () => {
    component.form.setErrors({ required: true });
    component.validate();
    expect(component.form.valid).toBeFalsy();
    expect(cdrMock.markForCheck).toHaveBeenCalled();
  });

  it('validate delete method for deleting case key from casesInCaseList', () => {
    const caseKey = 11;
    component.casesInCaseList = [11, 20, 33];
    component.newSelectedCases = [44, 55, 66];
    component.delete(caseKey);
    expect(component.casesInCaseList.length).toEqual(2);
    expect(component.casesInCaseList.indexOf(caseKey)).toEqual(-1);
    expect(component.newSelectedCases.length).toEqual(3);
    expect(component.deletingCases.includes(caseKey)).toBeTruthy();
  });

  it('validate delete method for deleting case key from casesInCaseList', () => {
    const caseKey = 33;
    component.casesInCaseList = [11, 20, 33];
    component.delete(caseKey);
    expect(component.casesInCaseList.length).toEqual(2);
    expect(component.casesInCaseList.indexOf(caseKey)).toEqual(-1);
    expect(component.deletingCases.includes(caseKey)).toBeTruthy();
  });

  it('validate onAdd method', () => {
    component.onAdd();
    expect(typeAheadConfigProviderMock.resolve).toHaveBeenCalledWith({ config: 'case', autoBind: true, multiselect: true, multipick: true });
    expect(picklistModalServiceMock.openModal).toHaveBeenCalled();
    modalRef.content.selectedRow$.subscribe(() => {
      expect(modalRef.content.selectedRow$).toHaveBeenCalled();
      expect(modalRef.content.onClose$).toHaveBeenCalled();
    });
  });

  it('validate getEntry method', () => {
    component.form.controls.value.setValue('test1');
    component.form.controls.primeCase.setValue('primeCase111');
    component.casesInCaseList = [11, 22, 33];
    component.getEntry();
    expect(component.entry.value).toEqual('test1');
    expect(component.entry.description).toBeNull();
    expect(component.entry.primeCase).toEqual('primeCase111');
    expect(component.entry.caseKeys).toEqual([11, 22, 33]);
  });

  it('validate revert with valid deleted casekey', () => {
    const caseKey = 11;
    component.deletingCases = [11, 22];
    component.revert(caseKey);
    expect(component.deletingCases.length).toEqual(1);
    expect(component.deletingCases.includes(caseKey)).toBeFalsy();
    expect(component.casesInCaseList.includes(caseKey)).toBeTruthy();
  });

  it('validate revert with invalid deleted casekey', () => {
    const caseKey = 10;
    component.deletingCases = [11, 22];
    component.revert(caseKey);
    expect(component.deletingCases.length).toEqual(2);
  });

  it('validate isDeletingCase with deleted casekey', () => {
    component.deletingCases = [11, 22];
    const result = component.isDeletingCase(11);
    expect(result).toBeTruthy();
  });

  it('validate isDeletingCase with non deleted casekey', () => {
    component.deletingCases = [11, 22];
    const result = component.isDeletingCase(10);
    expect(result).toBeFalsy();
  });

  it('validate isEditable method with editable case', () => {
    component.state = {
      maintainability: {
        canAdd: false,
        canDelete: false,
        canEdit: true
      },
      maintainabilityActions: {
        allowAdd: false,
        allowDelete: false,
        allowDuplicate: false,
        allowEdit: true,
        allowView: false,
        action: 'edit'
      }
    };
    const result = component.isEditable();
    expect(result).toBeTruthy();
  });

  it('validate isEditable method with non editable case', () => {
    component.state = {
      maintainability: {
        canAdd: false,
        canDelete: false,
        canEdit: true
      },
      maintainabilityActions: {
        allowAdd: false,
        allowDelete: false,
        allowDuplicate: false,
        allowEdit: true,
        allowView: false,
        action: 'view'
      }
    };
    const result = component.isEditable();
    expect(result).toBeFalsy();
  });

});
