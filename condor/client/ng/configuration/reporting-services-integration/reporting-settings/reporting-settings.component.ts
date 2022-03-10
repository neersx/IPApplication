import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, NgForm, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import * as _ from 'underscore';
import { ReportingConnectionStatus, ReportingServicesSetting, ReportingServicesViewData, SecurityElement } from '../reporting-services-integration-data';
import { ReportingIntegrationSettingsService } from '../reporting-services-integration.service';

@Component({
  selector: 'app-reporting-integration-settings',
  templateUrl: './reporting-settings.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ReportingSettingsComponent implements OnInit {
  @Input() viewData: ReportingServicesViewData;
  @ViewChild('settingsForm', { static: true }) form: NgForm;
  formData: ReportingServicesSetting = new ReportingServicesSetting();
  connectionStatus = ReportingConnectionStatus.None;
  reportingConnectionStatus = ReportingConnectionStatus;
  dataType: any = dataTypeEnum;
  maxTimeout = 60;
  maxMessagesize = 200;

  constructor(private readonly reportingIntegrationService: ReportingIntegrationSettingsService,
    private readonly notificationService: NotificationService,
    private readonly translate: TranslateService,
    private readonly state: StateService,
    private readonly cdr: ChangeDetectorRef
  ) {
    this.formData.security = new SecurityElement();
  }

  ngOnInit(): void {
    this.formData = this.viewData.settings;
  }

  save = () => {
    this.validateMaxMessageSize();
    this.validateTimeout();
    this.connectionStatus = ReportingConnectionStatus.None;
    if (this.form.valid) {
      this.reportingIntegrationService.save(this.formData).subscribe(response => {
        this.setErrorOnBaseUrl(response.invalidUrl);
        if (response.success) {
          this.notificationService.success();
          this.reload();
        }
      });
    }
    this.cdr.detectChanges();
  };

  testConnection = () => {
    this.validateMaxMessageSize();
    this.validateTimeout();
    this.validateSecuritySection();
    this.connectionStatus = ReportingConnectionStatus.None;
    if (this.form.valid) {
      this.connectionStatus = ReportingConnectionStatus.InProgress;
      this.reportingIntegrationService.testConnection(this.formData).subscribe(response => {
        this.setErrorOnBaseUrl(response.invalidUrl);
        this.connectionStatus = response.invalidUrl ? this.reportingConnectionStatus.None : response.success ? ReportingConnectionStatus.Success : ReportingConnectionStatus.Failed;
        this.cdr.detectChanges();
      });
    }
    this.cdr.detectChanges();
  };

  validateTimeout = (): any => {
    this.validateMaxValue('timeout', this.formData.timeout, this.maxTimeout);
  };

  validateMaxMessageSize = (): any => {
    this.validateMaxValue('maxSize', this.formData.messageSize, this.maxMessagesize);
  };

  private readonly validateMaxValue = (control, value, maxValue: number): void => {
    if (value) {
      const POSITIVEINTEGER_REGEXP = /^[1-9][0-9]*$/;
      if (!POSITIVEINTEGER_REGEXP.test(value)) {
        this.form.controls[control].markAsTouched();
        this.form.controls[control].setErrors({ positiveinteger: true });
      } else if (value > maxValue) {
        this.form.controls[control].markAsTouched();
        this.form.controls[control].setErrors({ 'reportingServices.configuration.maxSizeError': true });
      } else {
        this.form.controls[control].setErrors(null);
      }
    }
  };

  setErrorOnBaseUrl = (isInvalid: boolean): void => {
    if (isInvalid) {
      this.form.controls.baseUrl.markAsTouched();
      this.form.controls.baseUrl.setErrors({ pattern: true });
    } else {
      this.form.controls.baseUrl.setErrors(null);
    }
  };

  reload = () => {
    this.connectionStatus = ReportingConnectionStatus.None;
    this.state.reload(this.state.current.name);
  };

  canApply = (): boolean => {
    return this.form.dirty && this.form.valid;
  };

  canDiscard = (): boolean => {
    return this.form.dirty;
  };

  canTest = (): boolean => {
    return this.form.valid;
  };

  validateSecuritySection = (): void => {
    const secutirySection = this.formData.security;
    const controls = this.form.controls;
    let isValid = true;

    const isUserNameEmpty = _.isEmpty(secutirySection.username);
    const isPasswordEmpty = _.isEmpty(secutirySection.password);
    const isDomainEmpty = _.isEmpty(secutirySection.domain);

    if (isUserNameEmpty && isPasswordEmpty && isDomainEmpty) {
      controls.username.setValidators([]);
      controls.password.setValidators([]);
      controls.domain.setValidators([]);
      this.markAsValid(controls.username);
      this.markAsValid(controls.password);
      this.markAsValid(controls.domain);

      return;
    }

    if (isUserNameEmpty) {
      controls.username.setValidators([Validators.required]);
      isValid = false;
    }

    if (isPasswordEmpty) {
      controls.password.setValidators([Validators.required]);
      isValid = false;
    }

    if (isDomainEmpty) {
      controls.domain.setValidators([Validators.required]);
      isValid = false;
    }
    if (!isValid) {
      this.validateAllFormFields();
    }
  };

  private readonly markAsValid = (control: AbstractControl): void => {
    control.markAsUntouched();
    control.markAsPristine();
    control.updateValueAndValidity();
  };

  private readonly validateAllFormFields = () => {
    Object.keys(this.form.controls).forEach(field => {
      const control = this.form.controls[field];
      if (!control.dirty) {
        control.markAsTouched();
        control.markAsDirty();
      }
      control.updateValueAndValidity();
    });
  };
}
