import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { DmsIntegrationService } from 'configuration/dms-integration/dms-integration.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { take } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';

@Component({
  selector: 'ipx-i-manage-credentials-input',
  templateUrl: './i-manage-credentials-input.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IManageCredentialsInputComponent implements OnInit {
  @Input() databases: Array<any>;
  showUsername = true;
  showPassword = true;
  formGroup: FormGroup;
  onClose$ = new Subject();
  constructor(private readonly formBuilder: FormBuilder, private readonly sbsModalRef: BsModalRef, readonly notificationService: IpxNotificationService, readonly service: DmsIntegrationService, readonly cdr: ChangeDetectorRef) { }

  ngOnInit(): void {
    const credentials = this.service.getCredentials();
    const showCredentials = this.service.getRequiresCredentials(this.databases);
    this.showUsername = showCredentials.showUsername;
    this.showPassword = showCredentials.showPassword;
    let username = '';
    let password = '';
    if (credentials) {
      username = credentials.username;
      password = credentials.password;
    }
    this.formGroup = this.formBuilder.group({
      password: ['', [Validators.required]],
      username: ['', [Validators.required]]
    });
    this.formGroup.patchValue({ username, password });
    if (username) {
      this.formGroup.controls.username.markAsDirty();
    }
    if (password) {
      this.formGroup.controls.password.markAsDirty();
    }

    if (!this.showUsername) {
      this.formGroup.get('username').setValidators(null);

    }
    if (!this.showPassword) {
      this.formGroup.get('password').setValidators(null);
    }

    this.cdr.markForCheck();
  }

  apply = (event: Event): void => {
    if (this.formGroup.dirty && this.formGroup.status !== 'INVALID') {
      this.onClose$.next({ username: this.formGroup.value.username, password: this.formGroup.value.password });
      this.sbsModalRef.hide();
    }
  };

  cancel = (event: Event): void => {
    if (this.formGroup.dirty) {
      const modal = this.notificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          this.onClose$.next(null);
          this.sbsModalRef.hide();
        });
    } else {
      this.onClose$.next(null);
      this.sbsModalRef.hide();
    }
  };
}
