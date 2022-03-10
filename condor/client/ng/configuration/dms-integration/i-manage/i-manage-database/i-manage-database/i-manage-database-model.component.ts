import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, ValidationErrors, Validators } from '@angular/forms';
import { UUID } from 'angular2-uuid';
import { DmsIntegrationService } from 'configuration/dms-integration/dms-integration.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, Subject } from 'rxjs';
import { take } from 'rxjs/operators';
import { IpxTextFieldComponent } from 'shared/component/forms/ipx-text-field/ipx-text-field.component';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { Topic } from 'shared/component/topics/ipx-topic.model';

@Component({
  selector: 'app-i-manage-database-model',
  templateUrl: './i-manage-database-model.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IManageDatabaseModelComponent implements AfterViewInit, OnInit {

  @ViewChild('server', { static: true }) serverField: IpxTextFieldComponent;
  @ViewChild('credentialsPopup', { static: true }) credentialsPopup: TemplateRef<any>;
  @Input() isAdding: boolean;
  @Input() grid: any;
  @Input() dataItem: any;
  @Input() rowIndex: number;
  @Input() topic: Topic;
  credentialsFormGroup: FormGroup;
  formGroup: FormGroup;
  onClose$ = new Subject();
  integrationTypes = ['iManage Work API V1', 'iManage Work API V2', 'iManage COM'];
  connectionError: string;
  connectionMessage: string;
  loginTypes = ['UsernamePassword', 'TrustedLogin', 'TrustedLogin2', 'UsernameWithImpersonation', 'InprotechUsernameWithImpersonation'];
  iManageLoginTypes = ['OAuth 2.0'];
  shownLoginTypes = this.loginTypes;
  iComWarning = '';
  showCustomerId$ = new BehaviorSubject(false);
  showWorkApiV2$ = new BehaviorSubject(false);
  showPassword$ = new BehaviorSubject(false);
  validationInProgress = false;

  constructor(private readonly formBuilder: FormBuilder,
    private readonly sbsModalRef: BsModalRef,
    private readonly notificationService: IpxNotificationService,
    readonly cdr: ChangeDetectorRef,
    private readonly service: DmsIntegrationService) {
  }

  ngOnInit(): void {
    this.createFormGroup(this.dataItem, this.topic);
    this.credentialsFormGroup = this.formBuilder.group({
      password: ['', [Validators.required]],
      username: ['', [Validators.required]]
    });
  }

  ngAfterViewInit(): void {
    this.showCustomerId$.next(this.showCustomerId(this.formGroup.value.integrationType));
    this.showPassword$.next(this.showPassword(this.formGroup.value.loginType));
    this.updateLoginTypes(this.formGroup.value.integrationType);

    this.formGroup.controls.integrationType.valueChanges.subscribe(v => {
      if (this.showCustomerId(v)) {
        this.formGroup.controls.customerId.setValidators([Validators.required]);
        this.showCustomerId$.next(true);
      } else {
        this.formGroup.controls.customerId.setValidators([]);
        this.showCustomerId$.next(false);
      }
    });

    const removeLeadingSlash = (str: string) => {
      let newStr = str;
      if (newStr.endsWith('/')) {
        newStr = newStr.substr(0, newStr.length - 1);
      }

      return newStr;
    };

    this.formGroup.controls.server.valueChanges.subscribe(value => {
      // tslint:disable-next-line: strict-boolean-expressions
      const oldServer = removeLeadingSlash(this.formGroup.value.server || '');
      const newValue = removeLeadingSlash(value);
      this.formGroup.controls.authUrl.setValue(this.formGroup.value.authUrl.replace(oldServer, newValue));
      this.formGroup.controls.accessTokenUrl.setValue(this.formGroup.value.accessTokenUrl.replace(oldServer, newValue));
      this.formGroup.controls.authUrl.markAsTouched();
      this.formGroup.controls.authUrl.markAsDirty();
      this.formGroup.controls.accessTokenUrl.markAsTouched();
      this.formGroup.controls.accessTokenUrl.markAsDirty();
      this.cdr.markForCheck();
    });

    this.formGroup.controls.loginType.valueChanges.subscribe(v => {
      if (this.showPassword(v)) {
        this.formGroup.controls.password.setValidators([Validators.required]);
        this.showPassword$.next(true);
      } else {
        this.formGroup.controls.password.setValidators([]);
        this.showPassword$.next(false);
      }
    });
  }

  createFormGroup = (dataItem: any, topic: Topic): FormGroup => {
    if (dataItem) {
      const defaultCallbackUrl = (topic.params.viewData.defaultSiteUrls || []).map(url => url + '/api/dms/imanage/auth/redirect').join('\r\n');

      this.formGroup = this.formBuilder.group({
        siteDbId: new FormControl(dataItem.siteDbId),
        server: new FormControl(dataItem.server, [Validators.required, this.duplicateServerValidator, this.httpsOnly]),
        database: new FormControl(dataItem.database, [Validators.required, this.duplicateDatabaseValidator]),
        integrationType: new FormControl(dataItem.integrationType, [Validators.required]),
        loginType: new FormControl(dataItem.loginType, [Validators.required]),
        customerId: new FormControl(dataItem.customerId),
        password: new FormControl(dataItem.password),
        callbackUrl: new FormControl(dataItem.callbackUrl || defaultCallbackUrl),
        // tslint:disable-next-line: strict-boolean-expressions
        authUrl: new FormControl(dataItem.authUrl || (`${dataItem.server || ''}/auth/oauth2/authorize`), [this.httpsOnly]),
        // tslint:disable-next-line: strict-boolean-expressions
        accessTokenUrl: new FormControl(dataItem.accessTokenUrl || (`${dataItem.server || ''}/auth/oauth2/token`), [this.httpsOnly]),
        clientId: new FormControl(dataItem.clientId),
        clientSecret: new FormControl(dataItem.clientSecret),
        status: new FormControl(dataItem.status)
      });

      return this.formGroup;
    }

    return this.formBuilder.group({});
  };

  private readonly duplicateDatabaseValidator = (c: AbstractControl): ValidationErrors | null => {
    if (c.value && c.dirty) {
      const databases = c.value.split(',').map(database => database.trim().toLowerCase()).filter(_ => _) as Array<string>;
      const distinctDatabases = databases.filter((value, index, self) => self.indexOf(value) === index);
      if (databases.length !== distinctDatabases.length) {

        return { duplicateDatabases: 'duplicateDatabases' };
      }
    }

    return null;
  };

  private readonly httpsOnly = (c: AbstractControl): ValidationErrors | null => {
    if (c.value && c.parent && c.parent.value.loginType === 'OAuth 2.0') {
      const re = new RegExp('^https://', 'i');
      if (!re.test(c.value)) {
        return { httpsOnly: 'httpsOnly' };
      }
    }

    return null;
  };

  private readonly duplicateServerValidator = (c: AbstractControl): ValidationErrors | null => {
    if (c.value && c.dirty) {
      const siteDbId = c.parent.value.siteDbId;
      const dataRows = Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
      const existInRows = dataRows.some(r => r && r.server === c.value && r.siteDbId !== siteDbId);
      const formGroups = this.grid.rowEditFormGroups;
      const existInFGs = formGroups && Object.keys(formGroups).filter(k => (formGroups[k] && formGroups[k].value.server === c.value) && (formGroups[k].value.siteDbId !== siteDbId)).length > 0;
      if (existInFGs || existInRows) {

        return { duplicateServer: 'duplicateServer' };
      }
    }

    return null;
  };

  generateClientId = () => {
    this.formGroup.controls.clientId.setValue(UUID.UUID());
    this.formGroup.controls.clientId.markAsTouched();
    this.formGroup.controls.clientId.markAsDirty();
    this.cdr.markForCheck();
  };

  generateClientSecret = () => {
    this.formGroup.controls.clientSecret.setValue(UUID.UUID());
    this.formGroup.controls.clientSecret.markAsTouched();
    this.formGroup.controls.clientSecret.markAsDirty();
    this.cdr.markForCheck();
  };

  integrationTypeChange = (data: any) => {
    if (!this.showCustomerId(data)) {
      this.formGroup.controls.customerId.setValue(null);
    } else if (this.formGroup.value.customerId === null) {
      this.formGroup.controls.customerId.setValue(1);
    }
    this.updateLoginTypes(data);
    this.iComWarning = '';
    if (this.isiComIntegrationType(data)) {
      this.iComWarning = 'dmsIntegration.iManage.iComWarning';
    }
  };

  updateLoginTypes = (integrationType: any) => {
    if (integrationType === 'iManage Work API V2') {
      this.formGroup.controls.clientId.setValidators([Validators.required]);
      this.formGroup.controls.clientSecret.setValidators([Validators.required]);
      this.shownLoginTypes = this.iManageLoginTypes;
      if (!this.showWorkApiV2$.getValue()) {
        this.formGroup.controls.loginType.setValue(this.iManageLoginTypes[0]);
        this.formGroup.controls.loginType.updateValueAndValidity();
        this.showWorkApiV2$.next(true);
      }
    } else {
      this.formGroup.controls.clientId.clearValidators();
      this.formGroup.controls.clientSecret.clearValidators();
      this.shownLoginTypes = this.loginTypes;
      if (this.showWorkApiV2$.getValue()) {
        this.formGroup.controls.loginType.setValue(null);
        this.formGroup.controls.loginType.updateValueAndValidity();
        this.showWorkApiV2$.next(false);
      }
    }
    this.formGroup.controls.clientId.updateValueAndValidity();
    this.formGroup.controls.clientSecret.updateValueAndValidity();
    this.cdr.markForCheck();
  };

  loginTypeChange = (data: any) => {
    if (!this.showPassword(data)) {
      this.formGroup.controls.password.setValue(null);
    }
  };

  apply(event: Event): void {
    if (this.formGroup.dirty && this.formGroup.status !== 'INVALID') {
      this.validationInProgress = true;
      this.service.validateUrl$(this.formGroup.value.server, this.formGroup.value.integrationType)
        .pipe(take(1)).subscribe(r => {
          if (r) {
            this.formGroup.setErrors(null);
            const formStatus = { success: true, formGroup: this.formGroup };
            this.onClose$.next(formStatus);
            this.sbsModalRef.hide();
          } else {
            this.formGroup.controls.server.setErrors({ pattern: true });
            this.formGroup.controls.server.markAsDirty();
            this.formGroup.controls.server.markAsTouched();
            this.serverField.cdr.detectChanges();
          }
        }, null, () => {
          this.validationInProgress = false;
          this.cdr.detectChanges();
        });
    }
  }

  cancel = (event: Event): void => {
    if (this.formGroup.dirty) {
      const modal = this.notificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          if (this.isAdding) {
            this.formGroup.reset();
          }
          this.resetForm(this.formGroup.dirty);
        });
    } else {
      this.resetForm(false);
    }
  };

  resetForm = (isDirty: boolean): void => {
    if (this.dataItem.status === rowStatus.Adding) {
      this.grid.rowCancelHandler(this, this.rowIndex, this.formGroup.value);
    }
    // this.topic.setCount.emit(data.length);
    const formStatus = { success: isDirty, formGroup: this.formGroup };
    this.onClose$.next(formStatus);
    this.sbsModalRef.hide();
  };

  private readonly showCustomerId = (val: string): boolean => {
    return val === 'iManage Work API V2';
  };

  private readonly isiComIntegrationType = (val: string): boolean => {
    return val === 'iManage COM';
  };

  private readonly showPassword = (val: string): boolean => {
    return (val === 'UsernameWithImpersonation' || val === 'InprotechUsernameWithImpersonation');
  };
}
