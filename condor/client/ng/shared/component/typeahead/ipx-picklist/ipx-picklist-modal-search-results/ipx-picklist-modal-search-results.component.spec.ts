
import { async } from '@angular/core/testing';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { of } from 'rxjs';
import { TemplateType } from '../../ipx-autocomplete';
import { PicklistTemplateType } from '../../ipx-autocomplete/autocomplete/template.type';
import { IpxModalOptions } from '../ipx-picklist-modal-options';
import { IpxPicklistModalSearchResultsComponent } from '../ipx-picklist-modal-search-results/ipx-picklist-modal-search-results.component';

describe('IpxPicklistModalComponent', () => {
  let component: IpxPicklistModalSearchResultsComponent;
  let httpClientSpy: any;
  let serviceSpy: any;
  let localSettings: any;
  const gridNavigationService = {};

  beforeEach(async(() => {
    httpClientSpy = { get: jest.fn(), post: jest.fn() };
    serviceSpy = {
      nextModalState: jest.fn(), nextMaintenanceMetaData: jest.fn(), addOrUpdate$: jest.fn(),
      delete$: jest.fn(), getItems$: jest.fn(), discard$: jest.fn()
    };
    localSettings = new LocalSettingsMock();
    component = new IpxPicklistModalSearchResultsComponent(httpClientSpy, serviceSpy, gridNavigationService as any, localSettings);
  }));

  beforeEach(() => {
    component.modalOptions = new IpxModalOptions(false, 'test', [{ key: 'key1', value: 'value1' }, { key: 'key2', value: 'value2' }], false, false, '', null, null, false);
    component.typeaheadOptions = {
      textField: '',
      templateType: TemplateType.ItemCodeDesc,
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
    serviceSpy.getItems$.mockReturnValue(of({ columns: [{ code: true, field: 'key', hidden: false, title: '' }] }))
      .mockReturnValue(of({ columns: [{ field: 'key', hidden: false, title: '' }, { field: 'value', hidden: false, title: '' }], data: [], maintainability: {}, pagination: { total: 2 } }));
    component.ngOnInit();
    component.gridOptions._search = () => serviceSpy.getItems$();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should init kendogrid with correct pre-selected value', () => {
    expect(component.gridOptions).toBeDefined();
    expect(component.gridOptions.columns).toEqual([{ title: 'title1', field: 'field1' }, { title: 'title2', field: 'field2' }, { title: 'title3', field: 'field3' }]);
    expect(component.gridOptions.selectedRecords).toEqual({ rows: { rowKeyField: 'key', selectedKeys: ['key1', 'key2'], selectedRecords: [{ key: 'key1', value: 'value1' }, { key: 'key2', value: 'value2' }] } });
  });

  it('should init search with correct text value', () => {
    component.gridOptions._search();
    jest.spyOn(serviceSpy, 'getItems$');
    expect(serviceSpy.getItems$).toHaveBeenCalledTimes(1);
  });

  it('should select correctly', () => {
    jest.spyOn(serviceSpy, 'getItems$');
    jest.spyOn(component.onRowSelect, 'emit');
    component.onRowSelectionChanged({ rowSelection: [{ key: 'key3', value: 'value3' }] });
    // tslint:disable-next-line: no-unbound-method
    expect(component.onRowSelect.emit).toHaveBeenCalledWith({ value: [{ key: 'key3', value: 'value3' }] });
  });

  it('should clear correctly', () => {
    component.clear();
    jest.spyOn(serviceSpy, 'getItems$');
    // tslint:disable-next-line: no-unbound-method
    expect(component.searchValue).toEqual('');
    expect(component.gridOptions.selectedRecords.rows.selectedKeys).toEqual([]);
    expect(serviceSpy.getItems$).toHaveBeenCalledTimes(1);

  });

  it('autobind should return false if autobind property in typeaheadOption is set as false and search text is empty string', () => {
    component.typeaheadOptions = {
      autobind: false,
      picklistColumns: [{ field: 'key', hidden: false, title: '' }]
    };
    component.modalOptions.searchValue = '';
    component.ngOnInit();
    const gridoption = component.gridOptions;
    expect(gridoption.autobind).toBeFalsy();
  });

  it('autobind should return true if autobind property in typeaheadOption is set as true', () => {
    component.typeaheadOptions = {
      autobind: true,
      picklistColumns: [{ field: 'key', hidden: false, title: '' }]
    };
    component.modalOptions.searchValue = '';
    component.ngOnInit();
    const gridoption = component.gridOptions;
    expect(gridoption.autobind).toBeTruthy();
  });

  it('should perform search with correct text value', () => {
    component.search({ value: '1234' });
    expect(component.searchValue).toEqual('1234');
    expect(serviceSpy.getItems$).toHaveBeenCalledTimes(1);
  });

  it('should perform search with blank text value and autobind false and allowEmptySearch true', () => {
    component.typeaheadOptions.autobind = false;
    component.typeaheadOptions.allowEmptySearch = true;
    component.searchValue = '';
    component.search('');
    expect(serviceSpy.getItems$).toHaveBeenCalledTimes(1);
  });

});
