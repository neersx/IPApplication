import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormControl } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import * as _ from 'underscore';
import { UserPreferenceService } from '../user-preference.service';

@Component({
  selector: 'user-preference',
  templateUrl: './user-preference.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class UserPreferenceComponent implements OnInit {
  userPreference: string;
  errorMessage: any;
  appsDisabled: boolean;
  enabled: boolean;
  configureAppMode: boolean;
  configuredModes: Array<string>;
  changeUserPreferenceDebounce: Function;
  userPref: FormControl;

  constructor(private readonly service: UserPreferenceService,
    formbuilder: FormBuilder,
    private readonly notificationService: NotificationService,
    private readonly cdRef: ChangeDetectorRef
  ) {
    this.changeUserPreferenceDebounce = _.debounce(this.performUserPreferenceChange, 1000);
    this.userPref = formbuilder.control('app');
  }

  ngOnInit(): any {
    this.loadPreferences();
  }

  loadPreferences = () => {
    this.enabled = false;
    this.service.GetUserTwoFactorAuthPreferences().then(preferences => {
      this.userPref.setValue(preferences.preference);
      this.configuredModes = preferences.configuredModes;
      this.enabled = preferences.enabled;
      this.appsDisabled = !_.any(this.configuredModes, (mode) => mode === 'app');
      this.cdRef.markForCheck();
    });
  };

  performUserPreferenceChange = () => {
    this.service.SetUserTwoFactorAuthPreferences({
      Preference: this.userPref.value
    }).then(() => {
      this.notificationService.success();
    }).catch((e) => {
      this.errorMessage = e;
    });
  };

  removeExistingConfiguration = (event) => {
    event.stopPropagation();
    this.notificationService.confirm({
      message: 'twoFactorPreference.removalConfirmationText', cancel: 'Cancel',
      continue: 'Proceed'
    }).then(() => {
      this.service.RemoveTwoFactorAppConfiguration().then(() => {
        this.notificationService.success();
        this.loadPreferences();
      }).catch((e) => {
        this.errorMessage = e;
        this.cdRef.markForCheck();
      });
    });
  };

  startConfiguringApp = (event) => {
    this.configureAppMode = true;
    event.stopPropagation();
  };

  stopConfiguringApp = () => {
    this.configureAppMode = false;
  };
}
