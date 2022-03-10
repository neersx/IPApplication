import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { EditAttribute, RecordalElementModel } from 'configuration/recordal-type/recordal-type.model';
import { RecordalTypeService } from 'configuration/recordal-type/recordal-type.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject, Subscription } from 'rxjs';
import { distinctUntilChanged, take } from 'rxjs/operators';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';

@Component({
  selector: 'ipx-recordal-element',
  templateUrl: './recordal-element.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RecordalElementComponent implements AfterViewInit, OnDestroy, OnInit {
  @Input() isAdding = false;
  @Input() isAddAnother: boolean;
  @Input() grid: any;
  @Input() dataItem: RecordalElementModel;
  @Input() existingElements: Array<RecordalElementModel> = [];

  form: any;
  onClose$ = new Subject();
  subscription: Subscription;
  modalRef: BsModalRef;
  isSaveDisabled = true;
  isAddAnotherChecked = false;
  elementOptions = [];

  constructor(readonly service: RecordalTypeService,
    private readonly cdRef: ChangeDetectorRef,
    private readonly notificationService: IpxNotificationService,
    private readonly sbsModalRef: BsModalRef,
    readonly translate: TranslateService,
    private readonly formBuilder: FormBuilder) {
  }

  get attributeEnum(): typeof EditAttribute {
    return EditAttribute;
  }

  ngOnInit(): void {
    this.isAddAnotherChecked = this.service.isAddAnotherChecked.getValue();
    this.service.getAllElements().subscribe(res => {
      this.elementOptions = res;
      this.form = this.createFormGroup();
      this.setFormData(this.dataItem);
      this.form.valueChanges.pipe(distinctUntilChanged()).subscribe(value => {
        if (value) {
          this.isExistingElement();
          this.cdRef.markForCheck();
        }
      });
      this.cdRef.markForCheck();
    });
  }

  ngAfterViewInit(): void {
    if (this.form && !this.isAddAnother) {
      this.form.markAsPristine();
    }
  }

  setFormData(data: any): void {
    if (!data) { return; }
    this.form.patchValue({
      id: data.id,
      element: data.element,
      elementLabel: data.elementLabel,
      nameType: data.nameType,
      attribute: (data.attribute && data.attribute.key) ? data.attribute : (data.attribute === EditAttribute.Mandatory ? ({ key: data.attribute, value: 'Mandatory' }) : (data.attribute === EditAttribute.Display ? { key: data.attribute, value: 'Display' } : null))
    });
    this.cdRef.detectChanges();
  }

  createFormGroup = (): FormGroup => {
    this.form = this.formBuilder.group({
      id: this.dataItem.id,
      element: new FormControl(null, [Validators.required]),
      elementLabel: ['', Validators.required],
      nameType: [null, Validators.required],
      attribute: new FormControl(null, [Validators.required]),
      status: this.isAdding ? rowStatus.Adding : rowStatus.editing
    });

    return this.form;
  };

  submit(): void {
    if (this.form.valid) {
      this.onClose$.next({ success: true, formGroup: this.form });
      this.form.setErrors(null);
      this.sbsModalRef.hide();
    }
  }

  onAddAnotherChanged = (): void => {
    this.service.isAddAnotherChecked.next(this.isAddAnotherChecked);
  };

  private readonly isExistingElement = (): void => {
    const element = (this.form && this.form.value && this.form.value.element) ? this.form.value.element.value : null;
    const updatedElements = this.grid.wrapper.data && this.grid.wrapper.data.filter(x => x && x.id !== this.dataItem.id).map(y => y.element.value);
    const isExist = (this.existingElements && this.existingElements.length > 0)
      ? this.existingElements.filter(x => x && x.id !== this.dataItem.id).map(y => y && y.element && y.element.value).filter(x => x === element).length > 0
      : (updatedElements.filter(x => x === element).length > 0);

    const error = isExist ? { duplicateRecordalElement: 'duplicate' } : null;
    this.form.controls.element.setErrors(error);
  };

  ngOnDestroy(): void {
    if (!!this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  cancel(): void {
    if (this.form.dirty) {
      const modal = this.notificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          this.resetForm(true);
          this.sbsModalRef.hide();
        });
    } else {
      this.resetForm(true);
      this.sbsModalRef.hide();
    }
  }

  resetForm = (isDirty: boolean): void => {
    this.service.isAddAnotherChecked.next(false);
    this.form.reset();
    this.onClose$.next(isDirty);
    this.sbsModalRef.hide();
  };
}