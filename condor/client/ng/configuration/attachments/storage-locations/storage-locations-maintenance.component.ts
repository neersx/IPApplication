import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, ValidationErrors, Validators } from '@angular/forms';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { take } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';

@Component({
  selector: 'ipx-attachments-storage-locations-maintenance',
  templateUrl: './storage-locations-maintenance.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AttachmentsStorageLocationsMaintenanceComponent implements OnInit {
  formGroup: FormGroup;
  @Input() isAdding: boolean;
  @Input() grid: any;
  @Input() dataItem: any;
  @Input() rowIndex: any;
  @Input() validateUrl$: any;
  onClose$ = new Subject();
  validationInProgress = false;
  title: string;

  constructor(private readonly sbsModalRef: BsModalRef, private readonly notificationService: IpxNotificationService,
    readonly cdr: ChangeDetectorRef, private readonly formBuilderTemp: FormBuilder) {
  }

  ngOnInit(): void {
    this.title = this.isAdding ? 'attachmentsIntegration.storageLocations.maintenance.titleAdd' : 'attachmentsIntegration.storageLocations.maintenance.titleEdit';
    this.formGroup = this.createFormGroupTemp(this.dataItem);
  }

  createFormGroupTemp = (dataItem: any): FormGroup => {
    if (dataItem) {

      const formGroup = this.formBuilderTemp.group({
        storageLocationId: new FormControl(dataItem.storageLocationId),
        name: new FormControl(dataItem.name, [Validators.required, this.duplicateNameValidatorTemp]),
        path: new FormControl(dataItem.path, [Validators.required, this.duplicatePathValidator]),
        allowedFileExtensions: new FormControl(dataItem.allowedFileExtensions || 'doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx,html'),
        canUpload: new FormControl(dataItem.canUpload),
        status: new FormControl(this.dataItem.status)
      });

      return formGroup;
    }

    return this.formBuilderTemp.group({});
  };

  private readonly duplicateNameValidatorTemp = (c: AbstractControl): ValidationErrors | null => {
    if (c.value && c.dirty) {
      const storageLocationId = c.parent.value.storageLocationId;
      const dataRows = this.grid.getCurrentData();
      const existInRows = dataRows.some(r => r && r.name === c.value && r.storageLocationId !== storageLocationId);
      const formGroups = this.grid.rowEditFormGroups;
      const existInFGs = formGroups && Object.keys(formGroups).filter(k => (formGroups[k] && formGroups[k].value.name === c.value) && (formGroups[k].value.storageLocationId !== storageLocationId)).length > 0;

      if (existInFGs || existInRows) {

        return { duplicate: 'duplicate' };
      }
    }

    return null;
  };

  private readonly duplicatePathValidator = (c: AbstractControl): ValidationErrors | null => {
    if (c.value && c.dirty) {
      const storageLocationId = c.parent.value.storageLocationId;
      const dataRows = this.grid.getCurrentData();
      const existInRows = dataRows.some(r => r && r.path === c.value && r.storageLocationId !== storageLocationId);
      const formGroups = this.grid.rowEditFormGroups;
      const existInFGs = formGroups && Object.keys(formGroups).filter(k => (formGroups[k] && formGroups[k].value.path === c.value) && (formGroups[k].value.storageLocationId !== storageLocationId)).length > 0;

      if (existInFGs || existInRows) {

        return { duplicate: 'duplicate' };
      }
    }

    return null;
  };

  apply = (event: Event): void => {
    if (this.formGroup.dirty && this.formGroup.status !== 'INVALID') {
      this.validationInProgress = true;
      this.validateUrl$(this.formGroup.value.path, []).subscribe({
        next: (r: boolean) => {
          if (r) {
            this.closeModal(true);
          } else {
            this.formGroup.controls.path.markAsTouched();
            this.formGroup.controls.path.markAsDirty();
            this.formGroup.controls.path.setErrors({ invalidPath: true });
            this.cdr.detectChanges();
          }
        },
        complete: () => {
          this.validationInProgress = false;
          this.cdr.detectChanges();
        }
      });
    }
  };

  cancel = (): void => {
    if (this.formGroup.dirty) {
      const modal = this.notificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          if (this.isAdding) {
            this.grid.rowCancelHandler(this, this.rowIndex, this.formGroup.value);
            this.formGroup.reset();
          }
          this.closeModal();
        });
    } else {
      this.closeModal();
    }
  };

  private readonly closeModal = (changed?: boolean) => {
    this.onClose$.next({ success: changed, formGroup: this.formGroup });
    this.sbsModalRef.hide();
  };
}