import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { race } from 'rxjs';
import { map, take, takeUntil, takeWhile } from 'rxjs/operators';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { TimeRecordingPreferenceService } from './time-recording-preferences.service';

@Component({
    selector: 'time-recording-preferences',
    templateUrl: './time-recording-preferences.component.html',
    styleUrls: ['./time-recording-preferences.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class TimeRecordingPreferencesComponent implements OnInit {
    @Input() viewData: any;
    @ViewChild('f', { static: true }) f: NgForm;
    settings: Array<any>;
    isLoading = true;
    modalRef: any;
    hasUserPreferences: boolean;
    dataType: any = dataTypeEnum;
    initialSettings: Array<{id: number, booleanValue: boolean, integerValue?: number, dataType: string}>;
    hasErrors: boolean;

    constructor(readonly cdref: ChangeDetectorRef,
        private readonly preferences: TimeRecordingPreferenceService,
        private readonly notifications: NotificationService,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly $destroy: IpxDestroy) {
    }
    ngOnInit(): void {
        this._loadPreferences();
    }

    apply = (form: NgForm): void => {
        this.preferences.savePreferences(this.settings).subscribe((response: any) => {
            this.notifications.info({
                title: 'userPreferences.confirmation.title',
                message: 'userPreferences.confirmation.message'
            });
            this.hasUserPreferences = _.any(response, (s: any) => {
                return !s.isDefault;
            });
            this.viewData.onSuccess(response);
            form.form.reset(form.form.getRawValue(), { emitEvent: false });
            form.form.markAsPristine();
            this.cdref.detectChanges();
        });
    };

    trackByFn = (index: number, item: any) => {
        return index;
    };

    reset = (form: NgForm): void => {
        _.each(this.initialSettings, (s: any) => {
            if (s.dataType === 'B') {
                form.form.controls['userPreference_' + s.id].setValue(s.booleanValue, { emitEvent: true });
            }
            if (s.dataType === 'I') {
                form.form.controls['userPreference_' + s.id].setValue(s.integerValue, { emitEvent: true });
            }
            form.form.controls['userPreference_' + s.id].markAsPristine();
        });
        form.form.markAsPristine();
        this.cdref.detectChanges();
    };

    previewDefault = (form: NgForm): void => {
        if (form.dirty && this._hasNonDefaultPreferences()) {
            this.modalRef = this.ipxNotificationService.openDiscardModal();
            race(this.modalRef.content.confirmed$.pipe(map(() => true)),
                this.ipxNotificationService.onHide$.pipe(map(() => false)))
                .pipe(take(1), takeUntil(this.$destroy))
                .subscribe((confirmed: boolean) => {
                    if (!!confirmed) {
                        this._applyDefaults(form);
                    }});

            return;
        }
        this._applyDefaults(form);
    };

    private readonly _hasNonDefaultPreferences = (): boolean => {
        return _.any(this.settings, (s: any) => {

            return s.booleanValue !== s.defaultBooleanValue || s.integerValue !== s.defaultIntegerValue;
        });
    };

    resetToDefault = (form: NgForm): void => {
        this.modalRef = this.ipxNotificationService.openConfirmationModal('userPreferences.resetToDefault.confirmation.title', 'userPreferences.resetToDefault.confirmation.message', 'userPreferences.resetToDefault.confirmation.confirm', 'Cancel');
        race(this.modalRef.content.confirmed$.pipe(map(() => true)),
            this.ipxNotificationService.onHide$.pipe(map(() => false)))
            .pipe(take(1), takeUntil(this.$destroy))
            .subscribe((confirmed: boolean) => {
                if (!!confirmed) {
                    this.preferences.resetPreferences().subscribe((response: any) => {
                        this.notifications.info({
                            title: 'userPreferences.confirmation.title',
                            message: 'userPreferences.confirmation.message'
                        });
                        this.initialSettings = _.map(response, (s: any) => {
                            return { id: s.id, booleanValue: s.booleanValue, integerValue: s.integerValue, dataType: s.dataType };
                        });
                        this.settings = response;
                        this.hasUserPreferences = _.any(this.settings, (s: any) => {
                            return !s.isDefault;
                        });
                        this.cdref.detectChanges();
                        this.viewData.onSuccess(response);
                        form.form.markAsPristine();
                    });
                }
            });

        return;
    };

    booleanSettings(): Array<any> {
        return this.settings.filter((setting) => {

            return setting.dataType === 'B';
        });
    }

    integerSettings(): Array<any> {
        return this.settings.filter((setting) => {

            return setting.dataType === 'I';
        });
    }

    validateNumber(event: any, id: string, maxValue?: number): any {
        const control = this.f.form.controls['userPreference_' + id];
        if (!control) {

            return;
        }
        let hasErrors = false;
        if (event % 1 > 0) {
            control.setErrors({ wholeinteger: true });
            hasErrors = true;
        }
        if (isNaN(event) || event < 0) {
            control.setErrors({ nonnegativeinteger: true });
            hasErrors = true;
        }
        if (event > maxValue) {
            control.setErrors({ max: maxValue });
            hasErrors = true;
        }
        if (hasErrors) {
            this.hasErrors = true;
            this.cdref.detectChanges();

            return;
        }

        control.setErrors(null);
        this.hasErrors = false;
        this.cdref.detectChanges();
    }

    private readonly _applyDefaults = (form: NgForm): void => {
        _.each(this.settings, (s: any) => {
            if (s.dataType === 'B') {
                if (s.booleanValue !== s.defaultBooleanValue) {
                    form.form.controls['userPreference_' + s.id].markAsDirty();
                }
                form.form.controls['userPreference_' + s.id].setValue(s.defaultBooleanValue, { emitEvent: true });
            }
            if (s.dataType === 'I') {
                if (s.intergerValue !== s.defaultIntegerValue) {
                    form.form.controls['userPreference_' + s.id].markAsDirty();
                }
                form.form.controls['userPreference_' + s.id].setValue(s.defaultIntegerValue, { emitEvent: true });
            }
        });
    };

    private readonly _loadPreferences = (): void => {
        this.preferences.loadPreferences()
            .subscribe(response => {
                this.isLoading = false;
                this.initialSettings = _.map(response, (s: any) => {
                    return { id: s.id, booleanValue: s.booleanValue, integerValue: s.integerValue, dataType: s.dataType };
                });
                this.settings = response;
                this.hasUserPreferences = _.any(this.settings, (s: any) => {
                    return !s.isDefault;
                });
                this.cdref.detectChanges();
            });

        return;
    };
}
