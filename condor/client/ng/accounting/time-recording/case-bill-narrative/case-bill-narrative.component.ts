import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, Validators } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, take, takeUntil, takeWhile } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxTypeaheadComponent } from 'shared/component/typeahead/ipx-typeahead';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { CaseBillNarrativeService } from './case-bill-narrative.service';

@Component({
    selector: 'case-bill-narrative',
    templateUrl: './case-bill-narrative.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class CaseBillNarrativeComponent implements OnInit {
    @ViewChild('languageRef', { static: false }) _languageRef: IpxTypeaheadComponent;
    caseKey: number;
    allowRichText: boolean;
    form: any;
    onClose$ = new Subject();
    textType: string;
    caseReference: string;
    saveDisabled = true;
    steps = [];
    currentStep: any;
    isLoading = false;
    previousNotes: string;

    get language(): FormControl {
        return this.form.get('language') as FormControl;
    }

    constructor(private readonly service: CaseBillNarrativeService,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly sbsModalRef: BsModalRef,
        private readonly cdRef: ChangeDetectorRef,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutsService: IpxShortcutsService,
        private readonly notificationService: NotificationService,
        private readonly fb: FormBuilder) { }

    ngOnInit(): void {
        this.form = this.fb.group({
            language: new FormControl({ key: null }),
            notes: new FormControl('', [Validators.required])
        });

        this.service.getCaseNarativeDefaults(this.caseKey).subscribe((response: any) => {
            this.textType = response.textType;
            this.allowRichText = response.allowRichText;
            this.caseReference = response.caseReference;
        });

        this.getSteps(null);
        this.form.controls.notes.valueChanges.pipe(distinctUntilChanged()).subscribe((val) => {
            this.saveDisabled = false;
        });
        this.language.valueChanges.pipe(debounceTime(500), distinctUntilChanged()).subscribe((value: any) => {
            if (value) {
                this.onLanguageChange(value);
            }
        });
        this.handleShortcuts();
    }

    onLanguageChange = (event: any) => {
        if (this.form.dirty && !this.saveDisabled && !this.form.invalid) {
            const modal = this.ipxNotificationService.openDiscardModal();
            this.previousNotes = this.form.controls.notes.value;
            modal.content.confirmed$.pipe(
                take(1), distinctUntilChanged())
                .subscribe(() => {
                    this.previousNotes = null;
                    this.resetCurrentStepLanguage(event, false, true);
                });
            modal.content.cancelled$.pipe(takeWhile(() => !!modal))
                .subscribe(() => {
                    this.resetCurrentStepLanguage(event, true);
                    this.cdRef.detectChanges();
                });
        } else {
            this.resetCurrentStepLanguage(event);
        }
    };

    private readonly resetCurrentStepLanguage = (event: any, isCancelled = false, isDiscarded = false) => {
        if (isCancelled) {
            this.goTo(this.currentStep, true);

            return;
        }
        const lang = event && event.key ? event.key : null;
        const steps = this.steps.filter(l => l.language === null && lang === null || (l.language && l.language.key === lang));
        if (steps.length > 0) {
            const currentStep = _.first(steps);
            this.goTo(currentStep, isCancelled, isDiscarded);
        } else {
            _.each(this.steps, (step) => {
                step.selected = false;
            });
            this.setNotes(null);
        }
    };

    getSteps = (language: number | null) => {
        this.service.getAllCaseNarratives(this.caseKey).subscribe((response: any) => {
            this.steps = response;
            if (language) {
                const selectedStep = _.first(this.steps.filter(l => l.language !== null && l.language.key === language));
                this.removeSelectedStepFromOtherSteps(selectedStep);
            } else if (response && response.length > 0) {
                if (response[0].language) {
                    this.form.patchValue({ language: response[0].language }, { onlySelf: true, emitEvent: false });
                }
                this.setNotes(response[0].notes);
            }
        });
    };

    removeStep = (step: any) => {
        const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('modal.confirmDelete.message');

        notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
            .subscribe(() => {
                this.isLoading = true;
                this.cdRef.markForCheck();
                const data = {
                    language: step.language ? step.language.key : null,
                    caseKey: this.caseKey
                };
                this.service.deleteCaseBillNarrative(data).subscribe(res => {
                    const index = this.steps.indexOf(step);
                    if (index > -1) {
                        this.steps.splice(index, 1);
                    }
                    const nextStep = index > 0 ? index - 1 : 0;
                    if (this.steps.length > 0) {
                        this.goTo(this.steps[nextStep]);
                    } else {
                        this.form.patchValue({ language: null }, { onlySelf: true, emitEvent: false });
                        this.form.controls.language.markAsPristine();
                        this.setNotes(null);
                    }
                    this.isLoading = false;
                    this.notificationService.success();
                    this.cdRef.detectChanges();
                    if (!!this._languageRef) {
                        this._languageRef.focus();
                    }
                });
            });
    };

    private readonly removeSelectedStepFromOtherSteps = (currentStep, isCancelled = false) => {
        const getOtherSteps = _.filter(this.steps, (step: any) => {
            return step.id !== currentStep.id;
        });
        _.each(getOtherSteps, (step: any) => {
            step.selected = false;
        });

        currentStep.selected = true;
        if (this.language.value == null || currentStep.language == null || (this.language.value.key !== currentStep.language.key)) {
            this.form.patchValue({ language: currentStep.language }, { onlySelf: true, emitEvent: false });
        }
        if (isCancelled) {
            this.form.controls.notes.setValue(this.previousNotes);
        } else {
            this.setNotes(currentStep.notes);
        }
        this.currentStep = currentStep;
    };

    goTo = (step: any, isCancelled = false, isDiscarded = false) => {
        if (isDiscarded) {
            this.removeSelectedStepFromOtherSteps(step);
            this.resetControls();

            return;
        }
        if (this.form.dirty && !this.saveDisabled && !isCancelled) {
            const modal = this.ipxNotificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1), distinctUntilChanged())
                .subscribe(() => {
                    this.removeSelectedStepFromOtherSteps(step);
                });
        } else {
            this.removeSelectedStepFromOtherSteps(step, isCancelled);
            if (!isCancelled) { this.resetControls(); }
        }
    };

    private readonly resetControls = (): void => {
        this.form.controls.language.markAsUntouched();
        this.form.controls.language.markAsPristine();
        this.form.controls.notes.markAsUntouched();
        this.form.controls.notes.markAsPristine();
        this.cdRef.detectChanges();
    };

    setNotes = (notes: string): void => {
        this.form.controls.notes.setValue(notes);
        this.form.controls.notes.markAsUntouched();
        this.form.controls.notes.markAsPristine();
        this.saveDisabled = true;
        this.cdRef.markForCheck();
    };

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.SAVE, (): void => { this.onSave(); }],
            [RegisterableShortcuts.REVERT, (): void => { this.close(); }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    onSave = () => {
        if (this.form.dirty && !this.saveDisabled) {
            this.isLoading = true;
            const data = {
                language: this.form.controls.language.value && this.form.controls.language.value.key ? this.form.controls.language.value.key : null,
                notes: this.form.controls.notes.value,
                caseKey: this.caseKey
            };

            this.service.setCaseBillNarrative(data).subscribe(() => {
                this.notificationService.success('accounting.time.caseNarrative.success');
                this.isLoading = false;
                this.getSteps(data.language);
                this.resetControls();
                if (!!this._languageRef) {
                    this._languageRef.focus();
                }
            });
        }
    };

    close = () => {
        if (this.form.dirty && !this.saveDisabled) {
            const modal = this.ipxNotificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.sbsModalRef.hide();
                    this.onClose$.next(false);
                });
        } else {
            this.sbsModalRef.hide();
            this.onClose$.next(false);
        }
    };

    trackByFn = (index): any => {
        return index;
    };
}