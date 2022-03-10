import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, NgForm, ValidationErrors } from '@angular/forms';
import { DmsIntegrationService } from 'configuration/dms-integration/dms-integration.service';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { TagsErrorValidator } from 'shared/component/typeahead/ipx-typeahead/typeahead.config.provider';

@Component({
  selector: 'i-manage-workspaces',
  templateUrl: './i-manage-workspaces.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IManageWorkspacesComponent implements OnInit {
  @ViewChild('workspaceForm', { static: true }) form: NgForm;
  @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
  @Input() topic: Topic;
  gridOptions: IpxGridOptions;

  private readonly prefix = 'dmsIntegration.iManage.workspaces.caseSearchOptions.';
  searchFieldOptions = [
    { code: 'CustomField1', display: this.prefix + 'customField1' },
    { code: 'CustomField2', display: this.prefix + 'customField2' },
    { code: 'CustomField3', display: this.prefix + 'customField3' },
    { code: 'CustomField1And2', display: this.prefix + 'customField1And2' }];

  nameTypeClass: Array<any>;
  case = {
    searchField: '',
    subClass: '',
    subType: ''
  };
  constructor(private readonly dmsService: DmsIntegrationService, private readonly cdr: ChangeDetectorRef, private readonly formBuilder: FormBuilder) {
  }

  ngOnInit(): void {
    const defaultCase = {
      subType: 'work'
    };
    this.topic.getDataChanges = this.getChanges;
    const isCasePopulated = this.topic.params.viewData && this.topic.params.viewData.imanageSettings && this.topic.params.viewData.imanageSettings.case
      && Object.keys(this.topic.params.viewData.imanageSettings.case).some(k => this.topic.params.viewData.imanageSettings.case[k] != null);
    this.case = isCasePopulated ? this.topic.params.viewData.imanageSettings.case || defaultCase : defaultCase;
    this.nameTypeClass = this.topic.params.viewData && this.topic.params.viewData.imanageSettings ? this.topic.params.viewData.imanageSettings.nameTypes || [] : [];
    this.gridOptions = this.buildGridOptions();
    this.subscribeFormEvents();
  }

  private readonly getChanges = (): { [key: string]: any } => {
    const finalData = [];
    const formGroups = this.grid.rowEditFormGroups || {};
    const formKeys = Object.keys(formGroups);
    const data = this.grid.getCurrentData();
    data.forEach(d => {
      const key = String(d[this.gridOptions.rowMaintenance.rowEditKeyField]);
      if (formKeys.indexOf(key) !== -1) {
        finalData.push(formGroups[key].value);
      } else {
        finalData.push(d);
      }
    });

    const obj = {
      case: this.case,
      nameTypes: finalData.filter(d => d.status !== rowStatus.deleting)
    };

    return obj;
  };

  private readonly subscribeFormEvents = () => {
    this.form.statusChanges.subscribe(c => {
      this.topic.hasChanges = this.form.dirty;
      this.topic.setErrors(this.form.invalid || !this.grid.isValid());
      this.dmsService.raisePendingChanges(this.topic.hasChanges);
      this.dmsService.raiseHasErrors(this.form.invalid || !this.grid.isValid());
    });
  };

  updateChangeStatus = (): void => {
    this.grid.checkChanges();
    this.cdr.detectChanges();
    const dataRows = this.grid.getCurrentData();
    this.topic.hasChanges = dataRows.some((r) => r.status);
  };

  private readonly buildGridOptions = (): IpxGridOptions => {
    const options: IpxGridOptions = {
      sortable: false,
      showGridMessagesUsingInlineAlert: false,
      autobind: true,
      reorderable: false,
      pageable: false,
      enableGridAdd: true,
      selectable: {
        mode: 'single'
      },
      gridMessages: {
        noResultsFound: 'grid.messages.noItems',
        performSearch: ''
      },
      read$: () => {
        return of(this.nameTypeClass).pipe(delay(100));
      },
      onDataBound: (data: any) => {
        const total = data.total ? data.total : data.length;
        if (data && total && this.topic.setCount) {
          this.topic.setCount.emit(total);
        }
      },
      columns: this.getColumns(),
      canAdd: true,
      rowMaintenance: {
        canEdit: true,
        canDelete: true,
        rowEditKeyField: 'autoNumber'
      },
      // tslint:disable-next-line: unnecessary-bind
      createFormGroup: this.createFormGroup.bind(this)
    };

    return options;
  };

  createFormGroup = (dataItem: any): FormGroup => {
    const formGroup = this.formBuilder.group({
      nameTypePicklist: new FormControl(undefined, this.duplicateNameType),
      subClass: ['']
    });

    formGroup.statusChanges.subscribe(c => {
      this.topic.hasChanges = formGroup.dirty;
      this.topic.setErrors(this.form.invalid || !this.grid.isValid());
      this.dmsService.raisePendingChanges(this.topic.hasChanges);
      this.topic.hasErrors$.subscribe(err => {
        this.dmsService.raiseHasErrors(err);
      });
    });
    this.cdr.markForCheck();

    if (dataItem.nameTypePicklist || dataItem.subClass) {
      if (dataItem.nameTypePicklist) {
        formGroup.controls.nameTypePicklist.setValue(dataItem.nameTypePicklist);
      }

      if (dataItem.subClass) {
        formGroup.controls.subClass.setValue(dataItem.subClass);
      }
    }
    this.topic.setCount.emit(this.grid.getCurrentData().length);

    return formGroup;
  };

  private readonly getColumns = (): Array<GridColumnDefinition> => {
    return [
      {
        title: 'dmsIntegration.iManage.workspaces.nameType',
        field: 'nameType',
        sortable: false,
        template: true,
        width: 600
      }, {
        title: 'dmsIntegration.iManage.workspaces.subClass',
        field: 'subClass',
        sortable: false,
        template: true
      }
    ];
  };

  onRowDelete = () => {
    const data = this.grid.getCurrentData();
    this.topic.hasChanges = data.some(d => d.status === rowStatus.deleting)
      || this.form.dirty || this.grid.isDirty();
    this.dmsService.raisePendingChanges(this.topic.hasChanges);
    this.topic.setErrors(this.form.invalid || !this.grid.isValid());
    this.topic.setCount.emit(data.length);
  };

  private readonly duplicateNameType = (c: AbstractControl): ValidationErrors | null => {
    this.cdr.markForCheck();
    if (c.value && c.dirty) {
      const newIds = [].concat(...c.value).map(m => m.code).join(',');
      const dataRows = this.grid.getCurrentData().filter(d => d.status !== rowStatus.editing).map(d => [].concat(...d.nameTypePicklist));
      const dataRowsIds = dataRows.map(d => d.map(e => e.code)).map(d => d.join(',')).filter(x => x !== '');

      const fgs = this.grid.rowEditFormGroups;
      const fgDataRow = Object.keys(fgs || {})
        .filter(f => fgs[f].value)
        .map(f => [].concat(...fgs[f].value.nameTypePicklist));
      const fgDataRowIds = fgDataRow.map(d => d.map(e => e.code)).map(d => d.join(','));

      const allIds = dataRowsIds.concat(fgDataRowIds.filter(x => x !== ''));
      const counts = allIds.join(',').split(',').reduce((map, val) => {
        map[val] = (map[val] ? map[val] : 0) + 1;

        return map;
      }, {});
      const duplicates = [];
      newIds.split(',').forEach(x => {
        if (counts[x] > 1) {
          duplicates.push(x);
        }
      });

      if (duplicates.length > 0) {
        const errorObj: TagsErrorValidator = {
          validator: { duplicate: 'duplicate' },
          keys: duplicates,
          keysType: 'code',
          applyOnChange: true
        };

        return { duplicate: 'duplicate', errorObj };
      }

    }

    return null;
  };
}
