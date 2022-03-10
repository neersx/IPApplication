import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { TypeDecorator } from 'shared/component/utility/type.decorator';
import * as _ from 'underscore';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { PicklistMainainanceComponent } from '../ipx-picklist-maintenance-templates/ipx-picklist-mainainance.component';
import { DataItem } from './data-item-picklist.model';
import { IpxDataItemService } from './ipx-dataitem-picklist.service';

@TypeDecorator('DataItemPicklistComponent')
@Component({
  selector: 'data-item-picklist',
  templateUrl: './data-item-picklist.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DataItemPicklistComponent implements OnInit, AfterViewInit, PicklistMainainanceComponent {
  static componentName = 'DataItemPicklistComponent';
  form: FormGroup;
  errorStatus: Boolean;
  private _entry: DataItem;
  @Input() set entry(valueRecieve: DataItem) {
    this._entry = {
      key: null,
      code: null,
      value: null,
      itemGroups: [],
      entryPointUsage: null,
      isSqlStatement: true,
      returnsImage: false,
      useSourceFile: false,
      notes: null,
      sql: { sqlStatement: null, storedProcedure: null }
    };
    if (valueRecieve) {
      this._entry.key = valueRecieve.key;
    }
    this._entry = _.extend(this._entry, valueRecieve);
  }

  get entry(): DataItem {
    return this.getEntry();
  }

  constructor(private readonly service: IpxPicklistMaintenanceService,
    private readonly ipxDataItemService: IpxDataItemService,
    private readonly cdf: ChangeDetectorRef,
    private readonly notifaication: IpxNotificationService,
    private readonly notificationService: NotificationService) {
  }

  ngOnInit(): void {
    this.errorStatus = false;
    this.form = new FormGroup({
      isSqlStatement: new FormControl(true),
      code: new FormControl(null, [Validators.required, Validators.maxLength(40)]),
      value: new FormControl(null, [Validators.required]),
      itemGroups: new FormControl(null),
      entryPointUsage: new FormControl(null),
      returnsImage: new FormControl(false),
      useSourceFile: new FormControl(false),
      statement: new FormControl(null, [Validators.required]),
      procedurename: new FormControl(null, [Validators.required]),
      notes: new FormControl(null)
    });

    this.loadData();
  }

  ngAfterViewInit(): void {
    this.form.controls.entryPointUsage.markAsPristine();
    setTimeout(() => {
      this.form.controls.statement.markAsPristine();
      const state = this.service.modalStates$.getValue();
      state.canSave = false;
      this.service.nextModalState(state);
    });
  }

  loadData = () => {
    this.form.setValue({
      code: this._entry.code,
      value: this._entry.value,
      itemGroups: this._entry.itemGroups,
      entryPointUsage: this._entry.entryPointUsage,
      isSqlStatement: this._entry.isSqlStatement,
      returnsImage: this._entry.returnsImage,
      useSourceFile: this._entry.useSourceFile,
      statement: this._entry.sql.sqlStatement,
      procedurename: this._entry.sql.storedProcedure,
      notes: this._entry.notes
    });
    this.setFormStatus();
    this.form.statusChanges.subscribe((value) => {
      const state = this.service.modalStates$.getValue();
      state.canSave = value === 'VALID' && this.form.dirty;
      if (state.canSave) {
        if (this.form.controls.isSqlStatement.value && !this.form.controls.statement.value) {
          state.canSave = false;
        } else if (!this.form.controls.isSqlStatement.value && !this.form.controls.procedurename.value) {
          state.canSave = false;
        }
      }
      if (this.errorStatus) {
        state.canSave = false;
        this.errorStatus = false;
      }
      this.service.nextModalState(state);
    });
    this.form.controls.isSqlStatement.valueChanges.subscribe(checked => {
      if (checked) {
        this.form.controls.statement.enable();
      } else {
        this.form.controls.procedurename.enable();
      }
      this.form.updateValueAndValidity();
    });
  };

  setFormStatus(): void {
    if (this._entry.isSqlStatement) {
      this.form.controls.procedurename.disable();
    } else {
      this.form.controls.statement.disable();
    }
    this.form.updateValueAndValidity();
  }

  readonly getEntry = (): DataItem => {
    if (this.form) {
      this._entry.code = this.form.controls.code.value ? this.form.controls.code.value : '';
      this._entry.value = this.form.controls.value.value ? this.form.controls.value.value : '';
      this._entry.itemGroups = this.form.controls.itemGroups.value ? this.form.controls.itemGroups.value : [];
      this._entry.entryPointUsage = this.form.controls.entryPointUsage.value ? this.form.controls.entryPointUsage.value : {};
      this._entry.isSqlStatement = this.form.controls.isSqlStatement.value;
      this._entry.returnsImage = this.form.controls.returnsImage.value;
      this._entry.useSourceFile = this._entry.isSqlStatement ? false : this.form.controls.useSourceFile.value;
      this._entry.sql.sqlStatement = this.form.controls.statement.value ? this._entry.isSqlStatement ? this.form.controls.statement.value : '' : '';
      this._entry.sql.storedProcedure = this.form.controls.procedurename.value ? !this._entry.isSqlStatement ? this.form.controls.procedurename.value : '' : '';
      this._entry.notes = this.form.controls.notes.value ? this.form.controls.notes.value : '';
    }

    return this._entry;
  };

  resetSql(e): void {
    this.resetSqlError();
  }

  resetSqlError(): void {
    if (this.form.controls.isSqlStatement.value) {
      this.form.get('statement').setErrors(null);
    } else {
      this.form.get('procedurename').setErrors(null);
    }
    this.cdf.markForCheck();
  }

  validate(): void {
    const entity: any = {};
    entity.isSqlStatement = this.form.controls.isSqlStatement.value;
    entity.sql = entity.isSqlStatement ? { sqlStatement: this.form.controls.statement.value } : { storedProcedure: this.form.controls.procedurename.value };
    this.ipxDataItemService.validateSql(entity).subscribe(response => {
      if (response === null) {
        this.notificationService.success('dataItem.maintenance.testedsuccess');
      } else {
        this.errorStatus = true;
        if (entity.isSqlStatement) {
          this.form.get('statement').markAsTouched();
          this.form.get('statement').setErrors({ invalidsql: true });
        } else {
          this.form.get('procedurename').markAsTouched();
          this.form.get('procedurename').setErrors({ invalidsql: true });
        }
        this.notifaication.openAlertModal('field.errors.invalidsql', response.errors[0].message);
        this.cdf.markForCheck();
      }
    });
  }

  isDisabled(): Boolean {
    return this.form.controls.isSqlStatement.value ? this.form.controls.statement.value ? false : true : this.form.controls.procedurename.value ? false : true;
  }
}
