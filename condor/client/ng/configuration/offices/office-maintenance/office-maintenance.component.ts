import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, ValidatorFn, Validators } from '@angular/forms';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable, Subject, Subscription } from 'rxjs';
import { take, takeUntil } from 'rxjs/operators';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { OfficeData } from '../offices.model';
import { OfficeService } from '../offices.service';

@Component({
    selector: 'office-maintenance',
    templateUrl: './office-maintenance.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class OfficeMaintenanceComponent implements OnInit, OnDestroy {
    formGroup: FormGroup;
    errorStatus: Boolean;
    entry: OfficeData;
    @Input() state: string;
    @Input() entryId: number;
    editSubscription: Subscription;
    onClose$ = new Subject();
    addedRecordId$ = new Subject();
    title: string;
    printerOptions: Observable<Array<any>>;
    regions: Array<any>;
    dataType: any = dataTypeEnum;
    isCountryDisabled = false;
    canNavigate: Boolean;
    navData: {
        keys: Array<any>,
        totalRows: number,
        pageSize: number,
        fetchCallback(currentIndex: number): any
    };
    currentKey: number;

    constructor(private readonly service: OfficeService,
        private readonly notificationService: IpxNotificationService,
        private readonly formBuilder: FormBuilder,
        private readonly sbsModalRef: BsModalRef,
        private readonly cdRef: ChangeDetectorRef,
        private readonly gridNavService: GridNavigationService,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutsService: IpxShortcutsService) { }

    ngOnInit(): void {
        const titlePrefix = 'office.maintenance.';
        this.title = titlePrefix + (this.state === 'Add' ? 'addTitle' : 'editTitle');
        this.errorStatus = false;
        this.printerOptions = this.service.getPrinters();
        this.service.getRegions().subscribe((response: any) => {
            if (response) {
                this.regions = response.data;
            }
        });
        this.formGroup = this.formBuilder.group({
            id: [null],
            description: [null, { validators: Validators.required }],
            organization: [null],
            country: [null],
            language: [null],
            userCode: [null],
            cpaCode: [null],
            irnCode: [null],
            itemNoPrefix: [null, { validators: [this.validatePrefix()], updateOn: 'change' }],
            itemNoFrom: [null, { validators: [this.validateToAndFrom()], updateOn: 'change' }],
            itemNoTo: [null, { validators: [this.validateToAndFrom()], updateOn: 'change' }],
            printerCode: [null],
            regionCode: [null]
        });

        if (this.state === 'Add') {
            this.entry = {
                id: null,
                description: null,
                organization: null,
                country: null,
                language: null,
                userCode: null,
                cpaCode: null,
                irnCode: null,
                itemNoPrefix: null,
                itemNoFrom: null,
                itemNoTo: null,
                printerCode: null,
                regionCode: null
            };
        } else {
            this.canNavigate = true;
            this.getDetail();
            this.navData = {
                ...this.gridNavService.getNavigationData(),
                fetchCallback: (currentIndex: number): any => {
                    return this.gridNavService.fetchNext$(currentIndex).toPromise();
                }
            };
            this.currentKey = this.navData.keys.filter(k => k.value === this.entryId.toString())[0].key;
        }
        this.handleShortcuts();
    }

    loadData = () => {
        this.formGroup.setValue({
            id: this.entry.id,
            description: this.entry.description,
            organization: this.entry.organization,
            country: this.entry.country,
            regionCode: this.entry.regionCode,
            language: this.entry.language,
            printerCode: this.entry.printerCode,
            userCode: this.entry.userCode,
            cpaCode: this.entry.cpaCode,
            irnCode: this.entry.irnCode,
            itemNoPrefix: this.entry.itemNoPrefix,
            itemNoTo: this.entry.itemNoTo,
            itemNoFrom: this.entry.itemNoFrom
        });
        this.isCountryDisabled = this.entry.organization !== null;
        this.setFormStatus();
    };

    getNextItemDetail = (next: number) => {
        this.entryId = next;
        this.formGroup.markAsPristine();
        this.getDetail();
    };

    getDetail = () => {
        this.editSubscription = this.service.getOffice(this.entryId).subscribe(result => {
            this.entry = result;
            this.loadData();
            this.cdRef.markForCheck();
        });
    };

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.SAVE, (): void => { this.save(); }],
            [RegisterableShortcuts.REVERT, (): void => { this.cancel(); }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    ngOnDestroy(): void {
        if (!!this.editSubscription) {
            this.editSubscription.unsubscribe();
        }
    }

    setFromTo = ($event): void => {
        if (!$event) {
            this.itemNoTo.setValue(null);
            this.itemNoFrom.setValue(null);
        }
    };

    onChangeOrganisation = ($event): void => {
        if (!$event) {
            this.country.setValue(null);
            this.isCountryDisabled = false;
        } else {
            this.country.setValue({
                code: $event.countryCode,
                value: $event.countryName
            });
            this.isCountryDisabled = true;
        }
        this.cdRef.markForCheck();
    };

    private readonly validatePrefix = (): ValidatorFn => {
        return (control: AbstractControl): { [key: string]: any } | null => {
            if (!this.formGroup || !control || !control.value || control.value === '') {
                return null;
            }
            const regexMatcher = /^[a-zA-Z]{1,2}$/;
            if (!regexMatcher.test(control.value)) {
                return { 'office.only2letters': true };
            }

            return null;
        };
    };

    private readonly validateToAndFrom = (): ValidatorFn => {
        return (control: AbstractControl): { [key: string]: any } | null => {
            if (!this.formGroup || !control || !this.itemNoTo.value) {
                return null;
            }

            if (!this.itemNoFrom.value && this.itemNoTo.value) {
                return { 'office.fromShouldBeEnteredIfToExists': true };
            } else if (Math.trunc(this.itemNoTo.value) <= Math.trunc(this.itemNoFrom.value)) {
                return { 'office.fromShouldBeLessThanTo': true };
            }

            return null;
        };
    };

    private readonly setFormStatus = (): void => {
        this.formGroup.updateValueAndValidity();
    };

    get organization(): AbstractControl {
        return this.formGroup.get('organization');
    }

    get country(): AbstractControl {
        return this.formGroup.get('country');
    }

    get language(): AbstractControl {
        return this.formGroup.get('language');
    }

    get itemNoFrom(): FormControl {
        return this.formGroup.get('itemNoFrom') as FormControl;
    }

    get itemNoTo(): FormControl {
        return this.formGroup.get('itemNoTo') as FormControl;
    }

    save = (): void => {
        if (this.formGroup.dirty && this.formGroup.status !== 'INVALID') {
            this.service.saveOffice(this.formGroup.value).subscribe((response: any) => {
                if (response.errors && response.errors.length > 0) {
                    response.errors.forEach(error => {
                        if (error.field === 'description') {
                            this.formGroup.controls.description.setErrors({ duplicateOffice: 'duplicate' });
                        } else if (error.field === 'itemPrefix') {
                            this.formGroup.controls.itemNoPrefix.setErrors({ duplicateItemPrefix: true });
                        } else if (error.field === 'itemTo') {
                            this.formGroup.controls.itemNoTo.setErrors({ duplicateItemNo: true });
                        } else {
                            this.notificationService.openAlertModal('', '', error.message);
                        }
                    });
                } else {
                    this.formGroup.setErrors(null);
                    this.addedRecordId$.next(response.id);
                    this.onClose$.next(true);
                    this.sbsModalRef.hide();
                }
            });
        }
    };

    cancel = (): void => {
        if (this.formGroup.dirty) {
            const modal = this.notificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.resetForm();
                });
        } else {
            this.resetForm();
        }
    };

    resetForm = (): void => {
        this.formGroup.reset();
        this.onClose$.next(false);
        this.sbsModalRef.hide();
    };
}