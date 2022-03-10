import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, FormControl, FormGroup, Validators } from '@angular/forms';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject, Subscription } from 'rxjs';
import { take } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { KotFilterTypeEnum, KotTextType } from '../kot-text-types.model';
import { KotTextTypesService } from '../kot-text-types.service';

@Component({
  selector: 'kot-maintain-config',
  templateUrl: './kot-maintain-config.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class KotMaintainConfigComponent implements OnInit, OnDestroy {
  formGroup: FormGroup;
  errorStatus: Boolean;
  entry: KotTextType;
  @Input() state: string;
  @Input() entryId: number;
  @Input() filterBy: string;
  editSubscription: Subscription;
  onClose$ = new Subject();
  addedRecordId$ = new Subject();
  title: string;
  @ViewChild('caseTextTypeEl', { static: false }) caseTextTypeEl: any;
  @ViewChild('nameTextTypeEl', { static: false }) nameTextTypeEl: any;
  get KotFilterTypeEnum(): typeof KotFilterTypeEnum {
    return KotFilterTypeEnum;
  }

  constructor(private readonly service: KotTextTypesService,
    private readonly notificationService: IpxNotificationService,
    private readonly sbsModalRef: BsModalRef) { }

  ngOnInit(): void {
    const titlePrefix = 'kotTextTypes.maintenance.';
    this.title = titlePrefix + (this.state === 'Add' ? 'addTitle' : this.state === 'Duplicate' ? 'duplicateTitle' : 'editTitle');
    this.errorStatus = false;
    this.formGroup = new FormGroup({
      id: new FormControl(null),
      textType: new FormControl(true, [Validators.required]),
      caseTypes: new FormControl(null),
      nameTypes: new FormControl(null),
      roles: new FormControl(null),
      backgroundColor: new FormControl(null),
      hasCaseProgram: new FormControl(false),
      hasNameProgram: new FormControl(false),
      hasTimeProgram: new FormControl(false),
      hasBillingProgram: new FormControl(false),
      hasTaskPlannerProgram: new FormControl(false),
      isPending: new FormControl(false),
      isRegistered: new FormControl(false),
      isDead: new FormControl(false)
    });

    if (this.state === 'Add') {
      this.entry = {
        id: null,
        textType: null,
        hasCaseProgram: false,
        hasNameProgram: false,
        hasTimeProgram: false,
        hasBillingProgram: false,
        hasTaskPlannerProgram: false,
        isPending: false,
        isDead: false,
        isRegistered: false,
        caseTypes: null,
        nameTypes: null,
        roles: null,
        backgroundColor: null
      };
      this.loadData();
    } else {
      this.editSubscription = this.service.getKotTextTypeDetails(this.entryId, this.filterBy).subscribe(result => {
        this.entry = result;
        if (this.state === 'Duplicate') {
          this.entry.id = null;
          this.entry.textType = null;
        }
        this.loadData();
      });
    }
  }

  loadData = () => {
    this.formGroup.setValue({
      id: this.entry.id,
      textType: this.entry.textType,
      caseTypes: this.entry.caseTypes,
      nameTypes: this.entry.nameTypes,
      roles: this.entry.roles,
      backgroundColor: this.entry.backgroundColor,
      hasCaseProgram: this.entry.hasCaseProgram,
      hasNameProgram: this.entry.hasNameProgram,
      hasTimeProgram: this.entry.hasTimeProgram,
      hasBillingProgram: this.entry.hasBillingProgram,
      hasTaskPlannerProgram: this.entry.hasTaskPlannerProgram,
      isPending: this.entry.isPending,
      isRegistered: this.entry.isRegistered,
      isDead: this.entry.isDead
    });
    this.setFormStatus();
  };

  ngOnDestroy(): void {
    if (!!this.editSubscription) {
      this.editSubscription.unsubscribe();
    }
  }

  private readonly setFormStatus = (): void => {
    this.formGroup.updateValueAndValidity();
  };

  get textType(): AbstractControl {
    return this.formGroup.get('textType');
  }

  get backgroundColor(): AbstractControl {
    return this.formGroup.get('backgroundColor');
  }

  get caseTypes(): AbstractControl {
    return this.formGroup.get('caseTypes');
  }

  get nameTypes(): AbstractControl {
    return this.formGroup.get('nameTypes');
  }

  get roles(): AbstractControl {
    return this.formGroup.get('roles');
  }

  save = (): void => {
    if (this.formGroup.dirty && this.formGroup.status !== 'INVALID') {
      this.service.saveKotTextType(this.formGroup.value, this.filterBy).subscribe((response: any) => {
        if (response.error) {
          this.formGroup.controls.textType.setErrors({ duplicateTextType: 'duplicate' });
          if (this.filterBy === KotFilterTypeEnum.byCase) {
            this.caseTextTypeEl.el.nativeElement.querySelector('input').click();
          } else {
            this.nameTextTypeEl.el.nativeElement.querySelector('input').click();
          }
        } else {
          this.formGroup.setErrors(null);
          this.addedRecordId$.next(response.id);
          this.onClose$.next(true);
          this.sbsModalRef.hide();
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
          this.resetForm();
        });
    } else {
      this.resetForm();
    }
  };

  resetForm = (): void => {
    this.formGroup.reset();
    this.onClose$.next(false);
    this.sbsModalRef.hide();
  };
}