import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { DmsIntegrationService } from 'configuration/dms-integration/dms-integration.service';
import { WorkspaceType } from 'configuration/dms-integration/dms-models';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { of, Subject, Subscription } from 'rxjs';

@Component({
  selector: 'app-i-manage-test-workspace',
  templateUrl: './i-manage-test-workspace.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IManageTestWorkspaceComponent implements OnInit, OnDestroy {
  @ViewChild('testWorkspaceForm', { static: true }) form: NgForm;
  formData: any = {};
  iManageSettingData: any;
  results: any;
  showLoader = false;
  onClose$ = new Subject();
  workspaceType: WorkspaceType;
  subscription: Subscription;
  showUsername = true;
  showPassword = true;
  wsType = WorkspaceType;

  constructor(private readonly dmsService: DmsIntegrationService, private readonly cdr: ChangeDetectorRef,
    private readonly bsModalRef: BsModalRef) { }

  ngOnInit(): void {
    const credentials = this.dmsService.getCredentials();
    const showCredentials = this.dmsService.getRequiresCredentials(this.iManageSettingData.iManageSettings.Databases);
    this.showUsername = showCredentials.showUsername;
    this.showPassword = showCredentials.showPassword;
    if (credentials) {
      this.formData.username = credentials.username;
      this.formData.password = credentials.password;
    }
  }

  runTestWorkspace = () => {
    this.showLoader = true;
    this.results = null;

    this.iManageSettingData.username = this.formData.username;
    this.iManageSettingData.password = this.formData.password;
    const databases = this.iManageSettingData.iManageSettings.Databases as Array<any>;
    const signInToDms = databases.find(db => db.loginType === 'OAuth 2.0') != null;
    if (this.workspaceType === WorkspaceType.Case) {
      this.dmsService.testCaseWorkspace$(this.formData.caseIrn.key, this.iManageSettingData, signInToDms).then(resp => {
        if (resp) {
          this.onResultsReturned(resp);
        }
      });
    } else {
      this.dmsService.testNameWorkspace$(this.formData.name.key, this.iManageSettingData, signInToDms).then(resp => {
        if (resp) {
          this.onResultsReturned(resp);
        }
      });
    }
  };

  onResultsReturned = (response) => {
    this.results = response;
    this.showLoader = false;
    this.cdr.markForCheck();
  };

  cancel = (event: Event): void => {
    this.onClose$.next(null);
    this.bsModalRef.hide();
  };

  ngOnDestroy(): void {
    if (!!this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  byItem = (index: number, item: any): string => item;
}
