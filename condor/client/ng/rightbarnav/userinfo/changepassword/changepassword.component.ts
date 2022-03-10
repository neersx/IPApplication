import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import * as angular from 'angular';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { ChangePasswordService } from './changepassword.service';

@Component({
  selector: 'app-changepassword',
  templateUrl: './changepassword.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ChangePasswordComponent implements OnInit {
  appContext: any;
  formData: {
    oldPassword?: string,
    newPassword?: string,
    confirmNewPassword?: string,
    status?: string,
    error?: string,
    errorFromServer?: string
  };
  errorMessage: string;
  @ViewChild('f', { static: true }) ngForm: NgForm;
  passwordPolicyContent: Array<string> = [];

  constructor(
    private readonly bsModalRef: BsModalRef,
    private readonly changePasswordService: ChangePasswordService,
    private readonly notificationService: NotificationService,
    private readonly cdref: ChangeDetectorRef,
    private readonly translate: TranslateService) {
    this.formData = {};
  }

  ngOnInit(): void {
    this.passwordPolicyContent = [
      this.translate.instant('signin.passwordPolicyContentAtLeastEightCharacters'),
      this.translate.instant('signin.passwordPolicyContentAtLeastOneSpecialCharacter'),
      this.translate.instant('signin.passwordPolicyContentAtLeastOneUpperAndLowerCase'),
      this.translate.instant('signin.passwordPolicyContentAtLeastOneNumericValue')
    ];
  }

  verifyPassword = () => {
    this.clearError();
    const control = this.ngForm.controls.confirmNewPassword;
    if (this.formData.newPassword
      && this.formData.confirmNewPassword
      && this.formData.newPassword === this.formData.confirmNewPassword
    ) {
      control.setErrors(undefined);

      return true;
    }
    control.markAsTouched();
    control.markAsDirty();
    control.setErrors({ 'changePassword.newPasswordsDoNotMatch': true });
    this.ngForm.form.setErrors({ invalid: true });

    return false;
  };

  close(): void {
    this.bsModalRef.hide();
  }

  private readonly clearError = () => {
    this.formData.error = this.formData.errorFromServer = undefined;
    this.formData.status = undefined;
    this.errorMessage = undefined;
  };

  submit = (): void => {
    this.clearError();
    if (this.verifyPassword() && this.ngForm.form.valid) {
      const resetPasswordRequest = angular.extend({}, this.formData, {
        IsApps: true
      });
      this.changePasswordService.updateUserPassword(resetPasswordRequest).subscribe(data => {
        switch (data.status) {
          case 'success':
            this.formData.error = '';
            this.notificationService.success('signin.' + data.status);
            this.close();
            break;
          case 'passwordPolicyValidationFailed':
            if (data.hasPasswordReused) {
              this.formData.error = data.passwordPolicyValidationErrorMessage;
            } else {
              this.formData.error = 'signin.passwordPolicy-heading';
              this.formData.status = data.status;
            }
            break;
          default:
            this.formData.error = 'signin.' + data.status;
            this.formData.status = data.status;
            break;
        }
        this.cdref.markForCheck();
      }, () => {
        this.formData.errorFromServer = 'signin.passwordNotUpdated';
        this.cdref.markForCheck();
      });

    } else {
      this.validateAllFormFields();
    }
  };

  trackByFn = (index: number, item: any) => {
    return index;
  };

  private readonly validateAllFormFields = () => {
    Object.keys(this.ngForm.controls).forEach(field => {
      const control = this.ngForm.controls[field];
      if (!control.dirty) {
        control.markAsTouched();
        control.markAsDirty();
        control.updateValueAndValidity();
      }
    });
  };
}