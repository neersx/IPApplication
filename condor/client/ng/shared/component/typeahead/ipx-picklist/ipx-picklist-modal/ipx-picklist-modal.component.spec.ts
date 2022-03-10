
import { async, fakeAsync, tick } from '@angular/core/testing';
import * as angular from 'angular';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { MockComponent } from 'jestGlobalMocks';
import { ChangeDetectorRefMock, GridNavigationServiceMock, NotificationServiceMock, TaskPlannerPersistenceServiceMock } from 'mocks';
import { of } from 'rxjs';
import { delay, first } from 'rxjs/operators';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { PicklistTemplateType, TemplateType } from '../../ipx-autocomplete/autocomplete/template.type';
import { IpxModalOptions } from '../ipx-picklist-modal-options';
import { IpxPicklistSearchFieldComponent } from '../ipx-picklist-search-field/ipx-picklist-search-field.component';
import { IpxPicklistModalComponent } from './ipx-picklist-modal.component';

describe('IpxPicklistModalComponent', () => {
  let component: IpxPicklistModalComponent;
  let serviceSpy: any;
  let resultComponent: any;
  let bsModalRef: any;
  let componentFactoryResolver: any;
  let shortcutsService: IpxShortcutsServiceMock;
  const localSpy = {
    get: jest.fn(), set: jest.fn(), remove: jest.fn(), getUserName: jest.fn(), keys: {
      typeahead: { picklist: { previewActive: { getLocal: jest.fn(), setLocal: jest.fn() } } }
    }
  };
  const notificationServiceMock = new NotificationServiceMock();
  let gridNavigationService: GridNavigationServiceMock;
  const changeRefMock = new ChangeDetectorRefMock();
  const destroy$ = of({}).pipe(delay(1000));
  const persistenceServie = new TaskPlannerPersistenceServiceMock();
  beforeEach(async(() => {
    bsModalRef = { hide: jest.fn() };
    componentFactoryResolver = {};
    serviceSpy = {
      nextModalState: jest.fn(), nextMaintenanceMetaData: jest.fn(), addOrUpdate$: jest.fn(),
      delete$: jest.fn(), getItems$: jest.fn(), discard$: jest.fn(), nextMaintenanceMode: jest.fn(),
      maintenanceMetaData$: { getValue: jest.fn() }
    };
    gridNavigationService = new GridNavigationServiceMock();
    shortcutsService = new IpxShortcutsServiceMock();
    component = new IpxPicklistModalComponent(bsModalRef, componentFactoryResolver, serviceSpy, localSpy as any,
      notificationServiceMock as any, gridNavigationService as any, changeRefMock as any, shortcutsService as any,
      destroy$ as any, persistenceServie as any);
    resultComponent = MockComponent('ipx-picklist-modal-search-results');
    Object.assign(resultComponent, { search: jest.fn(), clear: jest.fn() });
    component.modalOptions = new IpxModalOptions(false, 'test', [{ key: 'key1', value: 'value1' }, { key: 'key2', value: 'value2' }], false, false, '', null, null, null, false);
    component.typeaheadOptions = {
      textField: '',
      templateType: TemplateType.ItemCodeDesc,
      maintenanceTemplate: 'testTemplate',
      apiUrl: 'abc', picklistTemplateType: PicklistTemplateType.Valid, maxResults: 10, keyField: 'key', picklistColumns: [{
        title: 'title1', field: 'field1'
      },
      {
        title: 'title2', field: 'field2'
      },
      {
        title: 'title3', field: 'field3'
      }]
    };
    serviceSpy.getItems$.mockReturnValue(of({ columns: [{ code: true, field: 'key', hidden: false, title: '' }] }));
    component.navData = {
      keys: [{ key: '1', value: '-134' }, { key: '2', value: '21' }, { key: '3', value: '-133' }, { key: '4', value: '51' }],
      totalRows: 4,
      pageSize: 0,
      fetchCallback: jest.fn()
    };
    // tslint:disable-next-line: no-unbound-method
    jest.spyOn(component, 'loadComponent').mockImplementation(() => angular.noop);
  }));

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize shortcuts', () => {
    component.ngOnInit();
    expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.ADD, RegisterableShortcuts.SAVE]);
  });

  it('should call add on event from shortcut service if maintanable picklist', fakeAsync(() => {
    const addSpy = jest.spyOn(component, 'onAdd');

    component.modalOptions.picklistCanMaintain = true;
    shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.ADD;
    component.ngOnInit();
    tick(shortcutsService.interval);

    expect(addSpy).toHaveBeenCalled();
  }));

  it('should not call add on event from shortcut service if not maintanable picklist', fakeAsync(() => {
    const addSpy = jest.spyOn(component, 'onAdd');

    component.modalOptions.picklistCanMaintain = false;
    shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.ADD;
    component.ngOnInit();
    tick(shortcutsService.interval);

    expect(addSpy).not.toHaveBeenCalled();
  }));

  it('should call search on event from shortcut service', fakeAsync(() => {
    // tslint:disable-next-line: no-unbound-method
    const saveSpy = jest.spyOn(component, 'onSave').mockImplementation(() => angular.noop);

    shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
    component.ngOnInit();
    tick(shortcutsService.interval);

    expect(saveSpy).toHaveBeenCalled();
  }));

  it('should assign correct template', () => {
    component.configuredTemplate$.pipe(first()).subscribe((v) => expect(v).toBe(PicklistTemplateType.NameFiltered));
  });
  it('should call search with value', () => {
    component.searchResult = resultComponent;
    component.picklistSearchField = new IpxPicklistSearchFieldComponent();
    component.picklistSearchField.model = 'test';
    component.search();
    // tslint:disable-next-line: no-unbound-method
    expect(component.searchResult.search).toHaveBeenCalledWith({ action: 'filtersChanged', value: 'test' });
  });

  it('should call search with onClose', () => {
    component.selectedRow$.pipe(
      first()
    ).subscribe(v => expect(v).toBe('test'));
    component.onClose();
  });

  it('should excute action clearly', () => {
    // tslint:disable: no-unbound-method
    jest.spyOn(component, 'loadComponent');
    jest.spyOn(component, 'onDelete');
    component.loadComponent = jest.fn(x => { return x; });
    component.onDelete = jest.fn(x => { return x; });
    component.excuteAction({ value: { title: 'title', columns: 'col' }, action: 'add' });
    expect(component.entry).toEqual({ title: 'title', columns: 'col' });
    expect(component.isMaintenanceMode$.getValue()).toEqual('add');
    expect(component.loadComponent).toHaveBeenCalledWith('testTemplate');
    expect(component.maintananceTitle).toEqual('picklistmodal.add');

    component.excuteAction({ value: { title: 'title', columns: 'col', key: 'key' }, action: 'duplicate' });
    expect(component.entry).toEqual({ title: 'title', columns: 'col' });
    expect(component.isMaintenanceMode$.getValue()).toEqual('duplicate');

    component.excuteAction({ value: { title: 'title', columns: 'col', key: 'key' }, action: 'edit' });
    expect(component.entry).toEqual({ title: 'title', columns: 'col', key: 'key' });
    expect(component.isMaintenanceMode$.getValue()).toEqual('edit');

    component.excuteAction({ value: { title: 'title', columns: 'col', key: 'key' }, action: 'delete' });
    expect(component.onDelete).toHaveBeenCalledWith({ title: 'title', columns: 'col', key: 'key' });
  });

  it('should excute action canNavigate true', () => {
    // tslint:disable: no-unbound-method
    jest.spyOn(component, 'loadComponent');
    jest.spyOn(component, 'onDelete');
    component.loadComponent = jest.fn(x => { return x; });
    component.onDelete = jest.fn(x => { return x; });
    component.modalOptions.canNavigate = true;
    component.entry = {
      key: -134,
      code: 'ACCEPTANCE_DEADLINE_DATE',
      value: 'Acceptance deadlinee'
    };
    jest.spyOn(gridNavigationService, 'getNavigationData').mockReturnValue(component.navData);
    component.typeaheadOptions = { apiUrl: 'api/picklists/dataItems', fetchItemParam: 'caseId' };
    jest.spyOn(component, 'fetchPicklistItem').mockReturnValue(of({
      key: 1032,
      code: 'Unit mismatch names on Case',
      value: 'unit alerts existwith the Case',
      entryPointUsage: {
        name: null,
        description: null
      }
    }));
    component.excuteAction({
      value: component.entry,
      action: 'edit'
    });
    expect(component.fetchPicklistItem).toHaveBeenCalled();
    expect(component.currentKey).toEqual('1');
    expect(component.canNavigate).toEqual(true);
  });

  it('should excute onAdd correctly', () => {
    component.loadComponent = jest.fn(x => { return x; });
    component.service.addOrUpdate$ = jest.fn();
    jest.spyOn(component, 'excuteAction');
    component.onAdd();
    expect(component.excuteAction).toHaveBeenCalledWith({ value: null, action: 'add' });
  });

  it('should excute fetchPicklistItem correctly', () => {
    component.typeaheadOptions = { apiUrl: 'api/picklists/dataItems', fetchItemParam: 'caseId' };
    component.entry = {
      key: 1032,
      value: 'Part 1',
      caseId: -487,
      rowKey: '1',
      selected: false
    };
    jest.spyOn(component, 'fetchPicklistItem').mockReturnValue(of({
      key: 1032,
      code: 'Unit mismatch names on Case',
      value: 'unit alerts existwith the Case',
      entryPointUsage: {
        name: null,
        description: null
      }
    }));
    component.fetchPicklistItem().subscribe(result => {
      expect(result).toBeTruthy();
      expect(result).toEqual({
        key: 1032,
        code: 'Unit mismatch names on Case',
        value: 'unit alerts existwith the Case',
        entryPointUsage: {
          name: null,
          description: null
        }
      });
    });
  });

  it('should excute onApply correctly', () => {
    component.loadComponent = jest.fn(x => { return x; });
    component.values = [{
      key: '107651',
      value: 'Float Chamber',
      inUse: false,
      selected: true
    }];
    component.onClose$.next = jest.fn();
    component.onApply();
    expect(component.onClose$.next).toHaveBeenCalled();
  });
  it('should excute onClose correctly', () => {
    component.loadComponent = jest.fn(x => { return x; });
    component.onClose$.next = jest.fn();
    component.onClose();
    expect(component.onClose$.next).toHaveBeenCalled();
  });

  it('should excute onDelete correctly', () => {
    component.loadComponent = jest.fn(x => { return x; });
    component.service.delete$ = jest.fn(v => of(''));

    component.onDelete({ key: 'key' });
    expect(component.service.delete$).toHaveBeenCalledWith('abc', 'key', null, expect.any(Function));
  });

  it('should excute getResultGridData correctly', () => {

    const caseCategories = [{ code: 'AB', isDefaultJurisdiction: false }, { code: 'XY', isDefaultJurisdiction: false }];
    const resultGridMock = {
      getCurrentData: jest.fn(x => { return caseCategories; })
    };
    component.searchResult = resultComponent;
    component.searchResult.resultGrid = resultGridMock as any;
    const result = component.getResultGridData();
    expect(component.searchResult.resultGrid.getCurrentData).toHaveBeenCalled();
    expect(result).toMatchObject(caseCategories);
  });

  it('showMoreInformation should return true if searchMoreInformation is not null or empty string', () => {

    component.typeaheadOptions = {
      searchMoreInformation: 'filter text'
    };
    const result = component.showMoreInformation();
    expect(result).toBeTruthy();
  });

  it('showMoreInformation should return true if searchMoreInformation is null or empty string', () => {
    component.typeaheadOptions = {
      searchMoreInformation: ''
    };
    const result = component.showMoreInformation();
    expect(result).toBeFalsy();
  });

  it('should excute updateSelection with picklistCanMaintain', () => {
    jest.spyOn(component, 'loadComponent');
    component.loadComponent = jest.fn(x => { return x; });
    component.modalOptions.extendedParams = jest.fn(x => { return { caseKeys: [2, 11] }; });
    component.extendedActions = { picklistCanMaintain: true };
    const dataItem = { key: 11, description: 'case lis desc', value: 'case list test', caseKeys: [2, 3, 4] };
    component.updateSelection(dataItem);
    expect(component.entry).toEqual({ key: 11, description: 'case lis desc', value: 'case list test', caseKeys: [2, 3, 4, 11], newlyAddedCaseKeys: [11] });
    expect(component.isMaintenanceMode$.getValue()).toEqual('edit');
  });

  it('should excute updateSelection with onapply', () => {
    component.modalOptions.extendedParams = jest.fn(x => { return x; });
    component.extendedActions = { picklistCanMaintain: false };
    const dataItem = { key: 11, description: 'case lis desc', value: 'case list test', caseKeys: [2, 3, 4] };
    component.values = [{
      key: '107651',
      value: 'case list test',
      selected: true
    }];
    component.onClose$.next = jest.fn();
    component.updateSelection(dataItem);
    expect(bsModalRef.hide).toHaveBeenCalled();
    expect(component.onClose$.next).toHaveBeenCalled();
  });

  it('should excute extendParams when action is add if extendedParams exist', () => {
    component.modalOptions.extendedParams = jest.fn(x => { return { caseId: 2, canAdd: true }; });
    const value = { value: null, action: 'add' };
    component.extendParams(value);
    expect(value.value).toEqual({ caseId: 2, canAdd: true });
  });

  it('should excute extendParams when action is edit if extendedParams exist', () => {
    component.modalOptions.extendedParams = jest.fn(x => { return { caseId: 2 }; });
    const value = { value: { canUpdate: true }, action: 'edit' };
    component.extendParams(value);
    expect(value.value).toEqual({ canUpdate: true, caseId: 2 });
  });
});
