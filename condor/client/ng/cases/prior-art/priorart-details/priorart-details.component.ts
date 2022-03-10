import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnDestroy, OnInit, Output, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, NgForm, Validators } from '@angular/forms';
import { StateService } from '@uirouter/angular';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { ReplaySubject } from 'rxjs';
import { finalize, take, takeUntil } from 'rxjs/operators';
import { SaveButtonComponent } from 'shared/component/buttons/buttons.component';
import { ElementBaseComponent } from 'shared/component/forms/element-base.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { LocaleDatePipe } from 'shared/pipes/locale-date.pipe';
import { PriorArtOrigin, PriorArtSearchResult } from '../priorart-search/priorart-search-model';
import { PriorArtService } from '../priorart.service';
@Component({
    selector: 'ipx-priorart-detail',
    templateUrl: './priorart-details.component.html',
    styleUrls: ['./priorart-details.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class PriorArtDetailsComponent implements OnInit, OnDestroy, AfterViewInit {
    @Input() details;
    @Input() isLiterature: boolean;
    @Input() translationsList: any = {};
    @Input() asNew?: boolean | false;
    formData: any = {};
    destroy: ReplaySubject<any> = new ReplaySubject<any>(1);
    hasPendingSave: boolean;
    originalData: PriorArtSearchResult = new PriorArtSearchResult();
    isFormDirty: boolean;
    showSaveButton: boolean;
    @Output() readonly onSave = new EventEmitter();
    @ViewChild('priorArtForm', { static: true }) ngForm: NgForm;
    @ViewChild('saveButton', { static: false }) saveButton: SaveButtonComponent;
    formGroup: FormGroup;
    get applicationDate(): AbstractControl {
        return this.formGroup.get('applicationDate');
    }
    get publishedDate(): AbstractControl {
        return this.formGroup.get('publishedDate');
    }
    get grantedDate(): AbstractControl {
        return this.formGroup.get('grantedDate');
    }
    get priorityDate(): AbstractControl {
        return this.formGroup.get('priorityDate');
    }
    get ptoCitedDate(): AbstractControl {
        return this.formGroup.get('ptoCitedDate');
    }
    get country(): AbstractControl {
        return this.formGroup.get('country');
    }
    get title(): AbstractControl {
        return this.formGroup.get('title');
    }

    constructor(private readonly service: PriorArtService, private readonly cdr: ChangeDetectorRef, private readonly formBuilder: FormBuilder,
        readonly ipxNotificationService: IpxNotificationService, private readonly localDatePipe: LocaleDatePipe,
        readonly stateService: StateService, private readonly dateHelper: DateHelper) {}

    ngOnInit(): void {
        if (this.details) {
            this.formGroup = this.createFormGroup({
                ...this.details
            });
            this.details.translation = !!this.details.translation ? this.details.translation.toString() : null;
            this.showSaveButton = (!!this.details.origin && this.details.origin === PriorArtOrigin.OriginInprotechPriorArt) ||
                (!this.details.origin);
            this.formData = this.details;
            // tslint:disable-next-line: strict-boolean-expressions
            this.details.abstract = this.details.abstract || null;
            // tslint:disable-next-line: strict-boolean-expressions
            this.details.title = this.details.title || null;
            // tslint:disable-next-line: strict-boolean-expressions
            this.details.citation = this.details.citation || null;
            // tslint:disable-next-line: strict-boolean-expressions
            this.details.name = this.details.name || null;
            // tslint:disable-next-line: strict-boolean-expressions
            this.details.refDocumentParts = this.details.refDocumentParts || null;
            // tslint:disable-next-line: strict-boolean-expressions
            this.details.description = this.details.description || null;
            // tslint:disable-next-line: strict-boolean-expressions
            this.details.comments = this.details.comments || null;
            // tslint:disable-next-line: strict-boolean-expressions
            this.details.city = this.details.city || null;
            this.ngForm.form.registerControl('applicationDate', this.applicationDate);
            this.ngForm.form.registerControl('publishedDate', this.publishedDate);
            this.ngForm.form.registerControl('grantedDate', this.grantedDate);
            this.ngForm.form.registerControl('priorityDate', this.priorityDate);
            this.ngForm.form.registerControl('ptoCitedDate', this.ptoCitedDate);
            this.ngForm.form.registerControl('country', this.country);
        }
        Object.assign(this.originalData, this.formData);
    }

    ngAfterViewInit(): void {
        this.isFormDirty = this.asNew;
        this.service.hasPendingChanges$.next(false);
        this.formData.hasChanges = false;
        if (this.asNew) {
            this.cdr.detectChanges();
        }
    }

    createFormGroup = (dataItem: any): FormGroup => {
        const formGroup = this.formBuilder.group({
            applicationDate: new FormControl(!!dataItem || !!dataItem.applicationDate ? { value: dataItem.applicationDate, disabled: dataItem.imported } : null),
            publishedDate: new FormControl(!!dataItem || !!dataItem.publishedDate ? { value: dataItem.publishedDate, disabled: dataItem.imported } : null),
            grantedDate: new FormControl(!!dataItem || !!dataItem.grantedDate ? { value: dataItem.grantedDate, disabled: dataItem.imported } : null),
            priorityDate: new FormControl(!!dataItem || !!dataItem.priorityDate ? { value: dataItem.priorityDate, disabled: dataItem.imported } : null),
            ptoCitedDate: new FormControl(!!dataItem || !!dataItem.ptoCitedDate ? { value: dataItem.ptoCitedDate, disabled: dataItem.imported } : null),
            country: new FormControl(!!dataItem || !!dataItem.country ? { key: dataItem.countryCode || dataItem.country, value: dataItem.countryName } : null),
            title: new FormControl(!!dataItem ? dataItem.title : null)
        });
        if (this.isLiterature) {
            formGroup.controls.title.setValidators(Validators.required);
        }

        return formGroup;
    };

    checkChanges(event: any): void {
        if (event === null) {

            return;
        }
        delete this.formData.hasChanges;
        delete this.originalData.hasChanges;
        if (JSON.stringify(this.originalData) !== JSON.stringify(this.formData) || this.datesChanged() || this.country.dirty || this.title.dirty) {
            this.isFormDirty = true;
            this.formData.hasChanges = true;
            if (!this.service.hasPendingChanges$.value) {
                this.service.hasPendingChanges$.next(true);
            }
        } else {
            this.isFormDirty = false;
            this.formData.hasChanges = false;
        }
        this.cdr.detectChanges();
    }

    datesChanged(): boolean {
        return this.originalData.grantedDate !== this.grantedDate.value ||
            this.originalData.priorityDate !== this.priorityDate.value ||
            this.originalData.ptoCitedDate !== this.ptoCitedDate.value ||
            this.originalData.publishedDate !== this.publishedDate.value ||
            this.originalData.applicationDate !== this.applicationDate.value;
    }

    _toLocalDate(dateTime: Date): Date {
        if (dateTime instanceof Date) {
            return new Date(dateTime.getFullYear(), dateTime.getMonth(), dateTime.getDate(), 0, 0, 0);
        }

        return null;
    }

    savePriorArt = (e?: any): void => {
        if (!this.showSaveButton || !this.isFormDirty || !this.formGroup.valid) {
            return;
        }

        if (this.isFormDirty) {
            if (!!e) {
                this.blurField(e.target);
            }
            this.formData.priorityDate = !!this.priorityDate.value ? this.dateHelper.toLocal(this._toLocalDate(this.priorityDate.value)) : null;
            this.formData.applicationDate = !!this.applicationDate.value ? this.dateHelper.toLocal(this._toLocalDate(this.applicationDate.value)) : null;
            this.formData.applicationFiledDate = !!this.applicationDate.value ? this.dateHelper.toLocal(this._toLocalDate(this.applicationDate.value)) : null;
            this.formData.publishedDate = !!this.publishedDate.value ? this.dateHelper.toLocal(this._toLocalDate(this.publishedDate.value)) : null;
            this.formData.grantedDate = !!this.grantedDate.value ? this.dateHelper.toLocal(this._toLocalDate(this.grantedDate.value)) : null;
            this.formData.ptoCitedDate = !!this.ptoCitedDate.value ? this.dateHelper.toLocal(this._toLocalDate(this.ptoCitedDate.value)) : null;
            this.formData.countryCode = !!this.country?.value?.value ? this.country.value.key : null;
            this.formData.isLiterature = this.isLiterature;
            this.formData.caseKey = this.stateService.params.caseKey;
            this.formData.sourceId = this.stateService.params.sourceId;
            if (this.isLiterature) {
                this.formData.title = this.title.value;
            }

            const formData = { ...this.formData };

            if (this.formData.id) {
                this.service.saveInprotechPriorArt$(formData)
                    .pipe(takeUntil(this.destroy), finalize(() => { this.hasPendingSave = false; }))
                    .subscribe((res: any) => {
                        if (!!res) {
                            if (res.result.result === 'success') {
                                this.formData.isSaved = true;
                                this.formData.hasChanges = false;
                                this.cdr.detectChanges();
                                const formStatus = { success: true };

                                this.onSave.emit(formStatus);
                                this.resetForm();
                            }
                        }
                        this.service.hasPendingChanges$.next(false);
                    });
            } else {
                if (this.isLiterature) {
                    this.createLiterature(formData);
                } else {
                    this.createPriorArt(formData);
                }
            }
        }
    };

    createPriorArt = (formData: any) => {
        this.service.existingPriorArt$(formData.country, formData.reference, formData.kind)
        .subscribe((response: any) => {
            if (response.result) {
                const messageParams = {
                    jurisdiction: this.formData.countryCode,
                    officialNumber: this.formData.reference,
                    kindCode: !!this.formData.kind ? ', ' + this.formData.kind : ''
                };
                const modal = this.ipxNotificationService.openConfirmationModal('priorart.matchingPriorArt', 'priorart.existingPriorArt', 'Proceed', 'Cancel', null, messageParams);
                modal.content.confirmed$.pipe(take(1)).subscribe(() => {
                    this._persist(formData);
                });
            } else {
                this._persist(formData);
            }
        });
    };

    createLiterature = (formData: any) => {
        this.service.existingLiterature$(formData.description, formData.name, formData.title,
            formData.refDocumentParts, formData.publisher, formData.city, this.country.value.key)
        .subscribe((response: any) => {
            if (response.result) {
                const message = !!formData.description ? formData.description : [formData.name, formData.title,
                    formData.refDocumentParts, formData.publisher, formData.city, this.country.value ? this.country.value.value : this.formData.countryName]
                    .filter(_ => _ && _.trim() !== '')
                    .join(', ');
                const messageParams = {
                    npl: message.length > 100 ? message.substr(0, 100) + '...' : message
                };
                const modal = this.ipxNotificationService.openConfirmationModal('priorart.matchingLiterature.title', 'priorart.matchingLiterature.message', 'Proceed', 'Cancel', null, messageParams);
                modal.content.confirmed$.pipe(take(1)).subscribe(() => {
                    if (!formData.description || !formData.description.trim()) {
                        formData.description = this._descriptionFromDetails();
                    }
                    this._persist(formData);
                });
            } else {
                if (!formData.description || !formData.description.trim()) {
                    formData.description = this._descriptionFromDetails();
                }
                this._persist(formData);
            }
        });
    };

    private readonly _persist = (formData: any) => {
        this.service.createInprotechPriorArt$(formData)
            .pipe(takeUntil(this.destroy), finalize(() => { this.hasPendingSave = false; }))
            .subscribe((success: any) => {
                this.formData.isSaved = true;
                this.formData.hasChanges = false;
                this.cdr.detectChanges();
                const formStatus = { success: true };

                this.onSave.emit(formStatus);
                this.resetForm();
                this.service.hasPendingChanges$.next(false);
            });
    };

    private _markFormPristine(form: NgForm): void {
        form.form.markAsPristine();
        Object.keys(form.form.controls).forEach(control => {
            form.controls[control].setErrors(null);
            this.cdr.detectChanges();
        });
    }

    isPageDirty = (): boolean => {
        return this.isFormDirty;
    };

    revertForm = (e: any): void => {
        if (!!e && !!e.dataItem && !!e.target) {
            this.blurField(e.target);
        }
        this.priorityDate.setValue(this.formData.priorityDate);
        this.applicationDate.setValue(this.formData.applicationDate);
        this.publishedDate.setValue(this.formData.publishedDate);
        this.grantedDate.setValue(this.formData.grantedDate);
        this.ptoCitedDate.setValue(this.formData.ptoCitedDate);
        this.country.setValue({key: this.formData.countryCode, value: this.formData.countryName});
        if (this.isLiterature) {
            this.title.setValue(this.formData.title);
        }

        Object.assign(this.formData, this.originalData);
        this.service.hasPendingChanges$.next(false);
        this.resetForm();
    };

    resetForm = (): void => {
        this.isFormDirty = false;
        this.formData.hasChanges = false;
        this._markFormPristine(this.ngForm);
        this.ngForm.form.markAsUntouched();
        this.service.hasPendingChanges$.next(false);
        this.cdr.detectChanges();
    };

    ngOnDestroy(): void {
        this.destroy.next(null);
        this.destroy.complete();
    }

    blurField = (field: ElementBaseComponent): void => {
        field.blur();
    };

    generateDescription = (): void => {
        const description = this._descriptionFromDetails();
        this.formData.description = description;
        if (this.formData.description !== this.originalData.description) {
            this.checkChanges(description);
            const descriptionPropertyName = 'Description';
            this.ngForm.controls[descriptionPropertyName].markAsDirty();
            this.cdr.detectChanges();
        }
    };

    private _descriptionFromDetails(): string {
        return [this.formData.name, this.title.value, this.publishedDate.value ? this.localDatePipe.transform(this.publishedDate.value, null) : null,
            this.formData.refDocumentParts, this.formData.publisher, this.formData.city, this.country.value ? this.country.value.value : this.formData.countryName]
            .filter(_ => _ && _.trim() !== '')
            .join(', ');
    }
}