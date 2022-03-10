import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, of, Subject, Subscription } from 'rxjs';
import { distinctUntilChanged, map, take } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { RecordalElementModel, RecordalTypePermissions, RecordalTypeRequest } from '../recordal-type.model';
import { RecordalTypeService } from '../recordal-type.service';
import { RecordalElementComponent } from './recordal-element/recordal-element.component';

@Component({
  selector: 'ipx-maintain-recordal-type',
  templateUrl: './maintain-recordal-type.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class MaintainRecordalTypeComponent implements AfterViewInit, OnDestroy, OnInit {
  @Input() state: any;
  @Input() dataItem: any;
  @Input() isAdding: boolean;
  @Input() existingTypes: any;
  @Input() viewData: RecordalTypePermissions;
  form: any;
  onClose$ = new Subject();
  subscription: Subscription;
  deleteSubscription: Subscription;
  modalRef: BsModalRef;
  isSaveDisabled = true;
  gridOptions: IpxGridOptions;
  selectedType: number;
  recordalTypeFormData: any;
  savedElements: Array<RecordalElementModel> = [];
  maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
  editedElements = [];
  addedRecordId$ = new Subject();
  @ViewChild('ipxKendoGridRef', { static: false }) grid: any;

  constructor(readonly service: RecordalTypeService,
    private readonly cdRef: ChangeDetectorRef,
    private readonly ipxNotificationService: IpxNotificationService,
    private readonly sbsModalRef: BsModalRef,
    private readonly notificationService: NotificationService,
    readonly translate: TranslateService,
    private readonly modalService: IpxModalService,
    readonly formBuilder: FormBuilder) {
  }

  ngOnInit(): void {
    this.form = this.createFormGroup();
    this.gridOptions = this.buildGridOptions();
    this.cdRef.markForCheck();
  }

  ngAfterViewInit(): void {
    if (!this.form) { return; }
    this.form.controls.recordalType.valueChanges.pipe(distinctUntilChanged()).subscribe(value => {
      if (value) {
        if (this.form.controls.recordalType.valid) {
          this.isExistingType();
        }
        this.isSaveDisabled = !this.form.dirty && !this.form.valid;
        this.cdRef.markForCheck();
      }
      this.cdRef.markForCheck();
    });
  }

  setFormData(data: any): void {
    if (!data) { return; }
    this.form.patchValue({
      recordalType: data.recordalType,
      recordalEvent: data.recordalEvent,
      recordalAction: data.recordalAction,
      requestEvent: data.requestEvent,
      requestAction: data.requestAction
    });
  }

  createFormGroup = (): FormGroup => {
    this.form = this.formBuilder.group({
      id: this.dataItem.id,
      recordalType: [null, Validators.required],
      requestEvent: [{ value: null }],
      recordalEvent: [{ value: null }],
      requestAction: [null],
      recordalAction: [],
      status: this.state
    });

    return this.form;
  };

  submit(): void {
    if (this.form.valid && this.form.value && this.form.dirty) {
      const isMandatoryExist = this.validateMandatoryElement();
      if (!isMandatoryExist) {
        this.notificationService.alert({ message: 'field.errors.mandatoryElementMustExist', continue: 'Ok' });

        return;
      }
      const request = this.prepareRequest(this.form.value);
      this.service.submitRecordalType(request).subscribe((res) => {
        if (res && res.id > 0) {
          this.addedRecordId$.next(res.id);
          this.onClose$.next({ success: true });
          this.form.setErrors(null);
          this.sbsModalRef.hide();
        } else {
          this.form.controls.recordalType.setErrors({ duplicateRecordalType: 'duplicate' });
        }
        this.cdRef.markForCheck();
      });
    }
  }

  private prepareRequest(form): RecordalTypeRequest {
    const request = new RecordalTypeRequest();

    request.id = this.dataItem.id ? this.dataItem.id : 0;
    request.recordalType = form.recordalType;
    request.recordalAction = form.recordalAction ? form.recordalAction.code : null;
    request.recordalEvent = form.recordalEvent ? form.recordalEvent.key : null;
    request.requestAction = form.requestAction ? form.requestAction.code : null;
    request.requestEvent = form.requestEvent ? form.requestEvent.key : null;
    request.elements = this.prepareElements(this.getEligibleDataRows());
    request.status = form.status;

    return request;
  }

  prepareElements(filters: any): Array<RecordalElementModel> {
    const els = [];
    filters.forEach(x => {
      const el = new RecordalElementModel(x.id);
      el.attribute = x.attribute ? x.attribute.key : null;
      el.element = x.element ? x.element.key : null;
      el.nameType = x.nameType ? x.nameType.code : null;
      el.elementLabel = x.elementLabel;
      el.id = x.id;
      el.status = x.status;
      els.push(el);
    });

    return els;
  }

  onRowAddedOrEdited(data: any): void {
    const modal = this.modalService.openModal(RecordalElementComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState: {
        isAdding: data.dataItem.status === rowStatus.Adding,
        grid: this.grid,
        dataItem: data.dataItem ? data.dataItem : new RecordalElementModel(data.dataItem.id),
        existingElements: this.savedElements
      }
    });
    modal.content.onClose$.subscribe(
      (event: any) => {
        if (event.formGroup) {
          this.editedElements.push(event.formGroup.value);
        }
        this.onCloseModal(event, data);
      }
    );
  }

  onCloseModal(event, data): void {
    if (event.success) {
      const rowObject = { rowIndex: data.rowIndex, dataItem: data.dataItem, formGroup: event.formGroup } as any;
      this.gridOptions.maintainFormGroup$.next(rowObject);
      this.form.markAsDirty();
      this.isSaveDisabled = false;
      if (this.service.isAddAnotherChecked.getValue()) {
        this.grid.addRow();
      } else if (this.modalService.modalRef) {
        this.modalService.modalRef.hide();
      }
    }
  }

  private readonly isExistingType = (): void => {
    const recordalType = this.form ? this.form.controls.recordalType.value : null;
    const isExist = this.existingTypes
      ? this.existingTypes.filter(x => x && x.recordalType === recordalType && x.id !== this.dataItem.id).length > 0 : null;

    const error = isExist ? { duplicateRecordalType: 'duplicate' } : null;
    this.form.controls.recordalType.setErrors(error);
    this.cdRef.markForCheck();
  };

  private readonly getEligibleDataRows = (): Array<any> => {

    return this.getEditedRows().filter(x => x && x.status !== undefined);
  };

  private validateMandatoryElement(): boolean {

    return this.getEditedRows().filter(x => x && (x.attribute.key === 'MAN' || x.attribute === 'MAN') && x.status !== 'D').length === 1;
  }

  getEditedRows = (): Array<any> => {
    return Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
  };

  clear(): void {
    this.gridOptions._search();
  }

  buildGridOptions(): IpxGridOptions {

    return {
      autobind: true,
      navigable: true,
      reorderable: true,
      read$: () => {
        if (this.dataItem.id === 0) { return of([]); }

        return this.service.getRecordalTypeFormData(this.dataItem.id).pipe(map(res => {
          this.setFormData(res);
          this.savedElements = res.elements;

          return res.elements;
        }));
      },
      rowMaintenance: {
        rowEditKeyField: 'id',
        canEdit: this.viewData.canEdit,
        canDelete: this.viewData.canDelete
      },
      maintainFormGroup$: this.maintainFormGroup$,
      canAdd: this.viewData.canAdd,
      enableGridAdd: true,
      columns: this.getColumns()
    };
  }

  onRowDeleted(): void {
    this.form.markAsDirty();
    this.isSaveDisabled = false;
    this.cdRef.markForCheck();
  }

  getColumns = (): Array<GridColumnDefinition> => {
    const columns: Array<GridColumnDefinition> = [{
      title: 'recordalType.recordalElement.column.element',
      field: 'element',
      template: true
    }, {
      title: 'recordalType.recordalElement.column.elementLabel',
      field: 'elementLabel',
      template: true
    }, {
      title: 'recordalType.recordalElement.column.nameType',
      field: 'nameType',
      template: true
    }, {
      title: 'recordalType.recordalElement.column.attribute',
      field: 'attribute',
      template: true
    }];

    return columns;
  };

  ngOnDestroy(): void {
    if (!!this.subscription) {
      this.subscription.unsubscribe();
      this.deleteSubscription.unsubscribe();
    }
  }

  cancelEdit(): void {
    this.isSaveDisabled = !this.isFormDirty();
  }

  private readonly isFormDirty = (): boolean => {
    this.grid.checkChanges();
    const isValid = this.grid.isValid();
    const dataRows = this.getEditedRows();
    const hasChanges = dataRows.some(x => x && x.status && x.status !== null) && isValid;

    return hasChanges;
  };

  cancel(): void {
    if (this.form.dirty) {
      const modal = this.ipxNotificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          this.sbsModalRef.hide();
        });
    } else {
      this.sbsModalRef.hide();
    }
  }

}
