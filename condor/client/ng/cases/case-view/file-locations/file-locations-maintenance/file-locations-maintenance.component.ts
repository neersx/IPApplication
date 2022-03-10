import { AfterViewInit, ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject, Subscription } from 'rxjs';
import { take } from 'rxjs/operators';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { ValidationError } from 'shared/component/forms/validation-error';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { FileHistoryComponent } from '../file-history/file-history.component';
import { FileLocationPermissions, WhenMovedEnum } from '../file-locations.component';
import { FileLocationsItems } from '../file-locations.model';
import { FileLocationsService } from '../file-locations.service';
declare var angular: any;

@Component({
    selector: 'file-locations-maintenance',
    templateUrl: './file-locations-maintenance.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class FileLocationsMaintenanceComponent implements OnInit, AfterViewInit, OnDestroy {

    @Input() isAdding: boolean;
    @Input() isAddAnother: boolean;
    @Input() grid: any;
    @Input() dataItem: any;
    @Input() rowIndex: any;
    formGroup: any;
    topic: any;
    onClose$ = new Subject();
    dataType: any = dataTypeEnum;
    isAddAnotherChecked = false;
    unitsPerHour = 10;
    timeFormat = 'HH:mm';
    permissions: FileLocationPermissions;
    hasError: boolean;
    subscription: Subscription;
    @ViewChild('filePartEl', { static: false }) filePartEl: any;
    @ViewChild('fileLocEl', { static: false }) fileLocEl: any;
    @ViewChild('whenMoved', { static: false }) whenMoved: any;
    @ViewChild('whenMovedTime', { static: false }) whenMovedTime: any;

    constructor(readonly service: FileLocationsService,
        private readonly notificationService: IpxNotificationService,
        private readonly sbsModalRef: BsModalRef,
        private readonly modalService: IpxModalService,
        readonly translate: TranslateService,
        private readonly formBuilder: FormBuilder) {
        this.filePartExtendQuery = this.filePartExtendQuery.bind(this);
        this.filePartextendedParam = this.filePartextendedParam.bind(this);
        this.filePartExternalScope = this.filePartExternalScope.bind(this);
    }

    ngOnInit(): void {
        this.createFormGroup(this.dataItem);
        this.isAddAnotherChecked = this.service.isAddAnotherChecked.getValue();
    }

    ngAfterViewInit(): void {
        if (!this.isAddAnother) {
            this.formGroup.markAsPristine();
        }
    }

    createFormGroup = (dataItem: FileLocationsItems): FormGroup => {
        if (dataItem) {
            this.formGroup = this.formBuilder.group({
                filePart: !dataItem.filePartId ? null : { key: dataItem.filePartId, value: dataItem.filePart },
                fileLocation: !dataItem.fileLocationId ? null : { key: dataItem.fileLocationId, value: dataItem.fileLocation, userCode: dataItem.barCode },
                bayNo: new FormControl(dataItem.bayNo, [Validators.maxLength(10)]),
                issuedBy: (dataItem.status === rowStatus.Adding) ? { key: this.permissions.DEFAULT_USER_ID, displayName: this.permissions.DISPLAY_NAME } : (!dataItem.issuedBy ? null : { key: dataItem.issuedById, displayName: dataItem.issuedBy }),
                whenMoved: new FormControl(this.getDateTime(dataItem.whenMoved, dataItem.status)),
                whenMovedTime: new FormControl(this.getDateTime(dataItem.whenMoved, dataItem.status)),
                barCode: new FormControl(dataItem.barCode),
                rowKey: new FormControl(dataItem.id),
                status: new FormControl(dataItem.status),
                filePartId: !dataItem.filePartId ? null : new FormControl(dataItem.filePartId),
                issuedById: !dataItem.issuedById ? null : new FormControl(dataItem.issuedById)
            });

            return this.formGroup;
        }

        return this.formBuilder.group({});
    };

    get fileLocation(): AbstractControl {
        return this.formGroup.get('fileLocation');
    }
    get filePart(): AbstractControl {
        return this.formGroup.get('filePart');
    }
    get issuedBy(): AbstractControl {
        return this.formGroup.get('issuedBy');
    }

    getDateTime(whenMovedDate: Date, status: string): Date {

        let finalDate = new Date(whenMovedDate);
        const timeOfDay = new Date();
        if (!whenMovedDate) {
            finalDate = timeOfDay;
        }
        if (status === rowStatus.Adding) {
            if (this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.AllowBothAndDateTime) {
                finalDate.setHours(timeOfDay.getHours());
                finalDate.setMinutes(timeOfDay.getMinutes());
                finalDate.setSeconds(0);
            }
            if (this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.AllowDateButTimeDisabledWithCurrentTime) {
                finalDate.setHours(timeOfDay.getHours());
                finalDate.setMinutes(timeOfDay.getMinutes());
                finalDate.setSeconds(timeOfDay.getSeconds());
            }
            if (this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.DisabledDateAndTimeWithSystemDateButZeroTime) {
                finalDate = timeOfDay;
                finalDate.setHours(0);
                finalDate.setMinutes(0);
                finalDate.setSeconds(0);
            }
            if (this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.DisabledDateAndTimeWithSystemDateTime) {
                finalDate = timeOfDay;
                finalDate.setHours(timeOfDay.getHours());
                finalDate.setMinutes(timeOfDay.getMinutes());
                finalDate.setSeconds(timeOfDay.getSeconds());
            }
        }

        return finalDate;
    }

    isMovedTimeDisabled = (): boolean => {
        return this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.AllowBothAndDateTime ? false : true;
    };

    isMovedDateDisabled = (): boolean => {
        if (this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.AllowBothAndDateTime || this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.AllowDateButTimeDisabledWithCurrentTime) {
            return false;
        }

        return true;
    };

    onChangeMovedTime = (event: Date): void => {
        if (event) {
            const movedDate = new Date(this.formGroup.value.whenMoved);
            movedDate.setHours(event.getHours());
            movedDate.setMinutes(event.getMinutes());
            if (this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.AllowBothAndDateTime) {
                movedDate.setSeconds(0);
            }
            this.formGroup.controls.whenMoved.setValue(movedDate);
            this.resetValidationErrors();
        }
    };

    filePartExtendQuery(query): any {
        const extended = angular.extend({}, query, {
            caseId: this.topic.params.viewData.caseKey
        });

        return extended;
    }

    filePartExternalScope(): any {
        return {
            value: this.topic.params.viewData.irn, label: this.translate.instant('caseview.fileLocations.caseReference')
        };
    }

    filePartextendedParam(query: any): any {
        return {
            ...query,
            caseId: this.topic.params.viewData.caseKey
        };
    }

    onChangeWhenMoved = (event: Date): void => {
        if (event) {
            this.formGroup.controls.whenMovedTime.setValue(event);
            this.resetValidationErrors();
        }
    };

    apply = (): void => {
        if (this.formGroup.dirty && this.formGroup.status !== 'INVALID') {
            this.formGroup.value.whenMoved = this.service.toLocalDate(this.formGroup.value.whenMoved, false);
            this.formGroup.value.issuedById = this.formGroup.value.issuedBy ? this.formGroup.value.issuedBy.key : null;
            this.formGroup.value.filePartId = this.formGroup.value.filePart ? this.formGroup.value.filePart.key : null;
            this.validate();
        }
    };

    validate = () => {
        const dataRows = Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
        const changedRows = [];
        dataRows.forEach((r) => {
            if (r && r.status !== null && this.grid.rowEditFormGroups && this.grid.rowEditFormGroups[r.id]) {
                const value = this.service.formatFileLocation({ ...this.grid.rowEditFormGroups[r.id].value });
                changedRows.push(value);
            }
        });
        const currentRow = this.service.formatFileLocation(this.formGroup.value);
        this.subscription = this.service.getValidationErrors(this.topic.params.viewData.caseKey, currentRow, changedRows)
            .subscribe((errors: Array<ValidationError>) => {
                if (errors && errors.length > 0) {
                    this.hasError = true;
                    errors.map((err) => {
                        if (err.field === 'fileLocation') {
                            this.showValidationErrors();
                            this.notificationService.openAlertModal('modal.unableToComplete', 'field.errors.duplicateFileLocations');
                        }
                        if (err.field === 'activeFileRequest') {
                            const info = this.translate.instant('field.errors.activeFileRequestExist', { caseIrn: this.topic.params.viewData.irn, dateRequired: err.customData });
                            const notificationRef = this.notificationService.openConfirmationModal('caseview.fileLocations.confirmFileLocation', info);
                            notificationRef.content.confirmed$.pipe(
                                take(1))
                                .subscribe(() => {
                                    this.formGroup.setErrors(null);
                                    this.onClose$.next({ success: true, formGroup: this.formGroup });
                                    this.sbsModalRef.hide();
                                });
                        }
                    });
                } else {
                    this.hasError = false;
                    this.formGroup.setErrors(null);
                    this.onClose$.next({ success: true, formGroup: this.formGroup });
                    this.sbsModalRef.hide();
                }
            });
    };

    openFileLocationHistory(): void {
        this.modalService.openModal(FileHistoryComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                topic: this.topic,
                isHosted: false,
                permissions: this.permissions,
                fileHistoryFromMaintenance: true,
                filePartId: this.formGroup.value.filePart ? this.formGroup.value.filePart.key : null
            }
        });
    }

    ngOnDestroy(): void {
        if (this.subscription) {
            this.subscription.unsubscribe();
        }
    }

    private showValidationErrors(): void {
        this.formGroup.controls.fileLocation.setErrors({ duplicate: 'duplicate' });
        this.formGroup.controls.fileLocation.markAsDirty();
        this.formGroup.controls.filePart.setErrors({ duplicate: 'duplicate' });
        this.formGroup.controls.filePart.markAsDirty();

        if (this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.AllowBothAndDateTime
            || this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.AllowDateButTimeDisabledWithCurrentTime) {
            this.formGroup.controls.whenMoved.setErrors({ duplicate: 'duplicate' });
            this.formGroup.controls.whenMoved.markAsDirty();
        }
        if (this.permissions.WHEN_MOVED_SETTINGS === WhenMovedEnum.AllowBothAndDateTime) {
            this.formGroup.controls.whenMovedTime.setErrors({ duplicate: 'duplicate' });
            this.formGroup.controls.whenMovedTime.markAsDirty();
        }
        this.clickEvents();
    }

    resetValidationErrors(): void {
        if (this.hasError) {
            this.formGroup.controls.fileLocation.setErrors(null);
            this.formGroup.controls.filePart.setErrors(null);
            this.formGroup.controls.whenMoved.setErrors(null);
            this.formGroup.controls.whenMovedTime.setErrors(null);
            this.clickEvents();
            this.hasError = false;
        }
    }

    private clickEvents(): void {
        this.filePartEl.el.nativeElement.querySelector('input').click();
        this.fileLocEl.el.nativeElement.querySelector('input').click();
        this.whenMovedTime.el.nativeElement.querySelector('input').click();
    }

    onCheckChanged = (): void => {
        this.service.isAddAnotherChecked.next(this.isAddAnotherChecked);
    };

    cancel = (): void => {
        if (this.formGroup.dirty) {
            const modal = this.notificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.resetForm(true);
                });
        } else {
            this.resetForm(false);
        }
    };

    onFileLocationChanged(event: any): void {
        if (event) {
            this.resetValidationErrors();
            this.formGroup.controls.barCode.setValue(event.userCode);
        }
    }

    resetForm = (isDirty: boolean): void => {
        if (this.dataItem.status === rowStatus.Adding && !this.dataItem.fileLocation) {
            this.grid.rowCancelHandler(this, this.rowIndex, this.formGroup.value);
        }
        this.service.isAddAnotherChecked.next(false);
        this.formGroup.reset();
        this.onClose$.next(isDirty);
        this.sbsModalRef.hide();
    };
}
