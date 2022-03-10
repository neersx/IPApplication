import { ChangeDetectionStrategy, Component, EventEmitter, OnInit, Output } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { WarningService } from '../warning-service';

@Component({
    selector: 'name-only-warnings',
    templateUrl: 'name-only-warnings.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
  })

export class NameOnlyWarningsComponent implements OnInit {
    name;
    debtorName;
    modalRef: BsModalRef;
    isPwdReqd = true;
    formGroup: FormGroup;
    isBlockedState = false;
    isValidPwd = true;
    restrictOnWip: boolean;

    @Output() private readonly btnClicked = new EventEmitter<boolean>();
    @Output() private readonly onBlocked = new EventEmitter<boolean>();

    constructor(private readonly formBuilder: FormBuilder,
                readonly warningService: WarningService,
                private readonly bsModalRef: BsModalRef) {
        this.modalRef = bsModalRef;
    }

    ngOnInit(): void {
        this.debtorName = this.name.displayName;
        this.isBlockedState = this.name.restriction.blocked;
        this.restrictOnWip = this.warningService.restrictOnWip;
        this.isPwdReqd = this.name.restriction.requirePassword && !this.isBlockedState && this.restrictOnWip;
        this.createFormGroup();
        if (!!this.name.billingCapCheckResult) {
            this.name.billingCapCheckResult.periodTypeDescription = this.warningService.setPeriodTypeDescription(this.name.billingCapCheckResult);
        }
    }

    createFormGroup(): FormGroup {
        this.formGroup = this.formBuilder.group({
            // tslint:disable-next-line: no-unbound-method
            pwd: ['', [Validators.required, this.passwordValidator]]
        });

        return this.formGroup;
    }

    proceed(): void {
        if (this.isPwdReqd && this.restrictOnWip) {
            this.warningService.validate(this.name.restriction.nameId, this.formGroup.get('pwd').value)
                .subscribe((isAuth: boolean) => {
                    if (isAuth) {
                        this.modalRef.hide();
                        this.btnClicked.emit(true);

                        return;
                    }
                    const val = this.formGroup.get('pwd').value;
                    this.formGroup.get('pwd').setErrors({ invalidpassword: true }, {emitEvent: true});
                    this.formGroup.get('pwd').setValue(val);
                    this.isValidPwd = false;

                    return;
                });

                return;
        }
        this.btnClicked.emit(true);
        this.modalRef.hide();
    }

    passwordValidator(control: AbstractControl): boolean | any {
        if (!control.errors || !control.errors.invalidpassword) {
            return true;
        }

        return {invalidpassword: true};
    }

    cancel(): void {
        this.btnClicked.emit(false);
        this.modalRef.hide();
    }

    blocked(): void {
        this.onBlocked.emit(this.isBlockedState);
        this.modalRef.hide();
    }
}
