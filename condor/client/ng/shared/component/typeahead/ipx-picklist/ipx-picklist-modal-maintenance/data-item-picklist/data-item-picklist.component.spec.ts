import { FormControl, FormGroup, Validators } from '@angular/forms';
import { ChangeDetectorRefMock, GridNavigationServiceMock, HttpClientMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { Observable } from 'rxjs';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { DataItemPicklistComponent } from './data-item-picklist.component';

describe('DataItemPicklistComponent', () => {
  let c: DataItemPicklistComponent;
  const httpMock = new HttpClientMock();
  const notificationServiceMock = new NotificationServiceMock();
  const changeRefMock = new ChangeDetectorRefMock();
  let picklistMaintenanceServiceMock;
  let dataItemService;
  let gridNavigationService: GridNavigationServiceMock;
  const translateServiceMock = new TranslateServiceMock();
  beforeEach(() => {
    dataItemService = {
      getDataItem: jest.fn().mockReturnValue(new Observable()),
      validateSql: jest.fn().mockReturnValue(new Observable())
    };
    gridNavigationService = new GridNavigationServiceMock();
    picklistMaintenanceServiceMock = new IpxPicklistMaintenanceService(httpMock as any, notificationServiceMock as any, translateServiceMock as any, gridNavigationService as any);
    c = new DataItemPicklistComponent(picklistMaintenanceServiceMock, dataItemService,
      changeRefMock as any, notificationServiceMock as any, notificationServiceMock as any);
  });

  it('should create', () => {
    expect(c).toBeTruthy();
  });

  it('should set the form after init at the time Add', () => {
    c.entry = {
      key: null,
      code: null,
      value: null,
      itemGroups: [],
      entryPointUsage: {},
      isSqlStatement: true,
      returnsImage: false,
      useSourceFile: false,
      notes: null,
      sql: {
        sqlStatement: null,
        storedProcedure: null
      }
    };
    c.ngOnInit();
    expect(c.errorStatus).toEqual(false);
    expect(c.form).toBeDefined();
    expect(c.form.controls.procedurename.disabled).toEqual(true);
  });

  it('should set the form after init at the time edit', () => {
    c.entry = {
      key: '1',
      code: null,
      value: null,
      itemGroups: [],
      entryPointUsage: {},
      isSqlStatement: true,
      returnsImage: false,
      useSourceFile: false,
      notes: null,
      sql: {
        sqlStatement: null,
        storedProcedure: null
      }
    };
    c.ngOnInit();
    expect(c.errorStatus).toEqual(false);
    expect(c.form).toBeDefined();
    expect(c.form.controls.procedurename.disabled).toEqual(true);
  });

  it('should set the the modal from getEntry method', () => {
    c.entry = {};
    c.form = new FormGroup({
      code: new FormControl('ACCEPTANCE_DEADLINE_DATE prateek', [Validators.required, Validators.maxLength(40)]),
      value: new FormControl('Acceptance deadline', [Validators.required]),
      itemGroups: new FormControl(null),
      entryPointUsage: new FormControl(null),
      returnsImage: new FormControl(false),
      useSourceFile: new FormControl(false),
      statement: new FormControl(null, [Validators.required]),
      procedurename: new FormControl(null, [Validators.required]),
      notes: new FormControl(null),
      isSqlStatement: new FormControl(true)
    });
    c.getEntry();
    expect(c.entry.code).toEqual('ACCEPTANCE_DEADLINE_DATE prateek');
  });

  it('should set resetSqlError', () => {
    c.entry = {};
    c.form = new FormGroup({
      code: new FormControl('ACCEPTANCE_DEADLINE_DATE prateek', [Validators.required, Validators.maxLength(40)]),
      value: new FormControl('Acceptance deadline', [Validators.required]),
      itemGroups: new FormControl(null),
      entryPointUsage: new FormControl(null),
      returnsImage: new FormControl(false),
      useSourceFile: new FormControl(false),
      statement: new FormControl('dirty', [Validators.required]),
      procedurename: new FormControl(null, [Validators.required]),
      notes: new FormControl(null),
      isSqlStatement: new FormControl(true)
    });
    c.resetSqlError();
    expect(c.form.controls.statement.dirty).toBe(false);
  });

  it('should call isDisabled', () => {
    c.form = new FormGroup({
      code: new FormControl('ACCEPTANCE_DEADLINE_DATE prateek', [Validators.required, Validators.maxLength(40)]),
      value: new FormControl('Acceptance deadline', [Validators.required]),
      itemGroups: new FormControl(null),
      entryPointUsage: new FormControl(null),
      returnsImage: new FormControl(false),
      useSourceFile: new FormControl(false),
      statement: new FormControl('value', [Validators.required]),
      procedurename: new FormControl(null, [Validators.required]),
      notes: new FormControl(null),
      isSqlStatement: new FormControl(true)
    });
    c.isDisabled();
    expect(c.isDisabled()).toBe(false);
  });

  it('should call validate', () => {
    c.form = new FormGroup({
      code: new FormControl('ACCEPTANCE_DEADLINE_DATE prateek', [Validators.required, Validators.maxLength(40)]),
      value: new FormControl('Acceptance deadline', [Validators.required]),
      itemGroups: new FormControl(null),
      entryPointUsage: new FormControl(null),
      returnsImage: new FormControl(false),
      useSourceFile: new FormControl(false),
      statement: new FormControl('value', [Validators.required]),
      procedurename: new FormControl(null, [Validators.required]),
      notes: new FormControl(null),
      isSqlStatement: new FormControl(true)
    });
    c.validate();
    const params = {
      isSqlStatement: false,
      sql: {
        storedProcedure: 'ipw_ListBackgroundProcesses'
      }
    };
    dataItemService.validateSql(params).subscribe(arg => {
      expect(arg).toBeDefined();
    });
  });
});
