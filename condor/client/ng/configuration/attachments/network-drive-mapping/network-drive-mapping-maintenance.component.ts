import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, ValidationErrors, Validators } from '@angular/forms';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { take } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { AttachmentConfigurationService } from '../attachments-configuration.service';

@Component({
  selector: 'ipx-attachments-network-drive-mapping-maintenance',
  templateUrl: './network-drive-mapping-maintenance.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class NetworkDriveMappingMaintenanceComponent implements OnInit {
  formGroup: FormGroup;
  @Input() isAdding: boolean;
  @Input() grid: any;
  @Input() dataItem: any;
  @Input() rowIndex: any;
  onClose$ = new Subject();
  validationInProgress = false;
  driveLetters: Array<any>;
  title: string;

  constructor(private readonly sbsModalRef: BsModalRef, private readonly notificationService: IpxNotificationService, readonly cdr: ChangeDetectorRef,
    private readonly service: AttachmentConfigurationService, private readonly formBuilderTemp: FormBuilder) {
  }

  ngOnInit(): void {
    this.driveLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
    this.title = this.isAdding ? 'attachmentsIntegration.networkDriveMapping.maintenance.titleAdd' : 'attachmentsIntegration.networkDriveMapping.maintenance.titleEdit';
    this.formGroup = this.createFormGroupTemp();
  }

  createFormGroupTemp = (): FormGroup => {
    if (this.dataItem) {
      const formGroup = this.formBuilderTemp.group({
        networkDriveMappingId: new FormControl(this.dataItem.networkDriveMappingId),
        driveLetter: new FormControl(this.dataItem.driveLetter, [Validators.required, this.duplicateNameValidatorTemp]),
        uncPath: new FormControl(this.dataItem.uncPath, [Validators.required]),
        status: new FormControl(this.dataItem.status)
      });

      return formGroup;
    }

    return this.formBuilderTemp.group({});
  };

  private readonly duplicateNameValidatorTemp = (c: AbstractControl): ValidationErrors | null => {
    if (c.value && c.dirty) {
      const networkDriveMappingId = c.parent.value.networkDriveMappingId;
      const dataRows = this.grid.getCurrentData();
      const existInRows = dataRows.some(r => r && r.driveLetter === c.value && r.networkDriveMappingId !== networkDriveMappingId);
      const formGroups = this.grid.rowEditFormGroups;
      const existInFGs = formGroups && Object.keys(formGroups).filter(k => (formGroups[k] && formGroups[k].value.driveLetter === c.value) && (formGroups[k].value.networkDriveMappingId !== networkDriveMappingId)).length > 0;

      if (existInFGs || existInRows) {

        return { duplicate: 'duplicate' };
      }
    }

    return null;
  };

  apply = (event: Event): void => {
    if (this.formGroup.dirty && this.formGroup.status !== 'INVALID') {
      this.validationInProgress = true;
      this.service.validateUrl$(this.formGroup.value.uncPath, []).subscribe({
        next: (r: boolean) => {
          if (r) {
            this.closeModal(true);
          } else {
            this.formGroup.controls.uncPath.markAsTouched();
            this.formGroup.controls.uncPath.markAsDirty();
            this.formGroup.controls.uncPath.setErrors({ invalidPath: true });
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