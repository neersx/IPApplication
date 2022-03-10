import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, Renderer2, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { parse } from '@uirouter/angular';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject, Subscription } from 'rxjs';
import { take, takeUntil } from 'rxjs/operators';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { ExchangeRateScheduleItems, ExchangeRateScheduleRequest } from '../exchange-rate-schedule.model';
import { ExchangeRateScheduleService } from '../exchange-rate-schedule.service';

@Component({
    selector: 'ipx-maintain-exchange-rate-schedule',
    templateUrl: './maintain-exchange-rate-schedule.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class MaintainExchangeRateScheduleComponent implements OnInit {
    @Input() id: any;
    @Input() isAdding: boolean;
    @ViewChild('dateChanged', { static: false }) dateChangedView: any;
    form: any;
    canNavigate: boolean;
    entry: ExchangeRateScheduleItems;
    navData: {
        keys: Array<any>,
        totalRows: number,
        pageSize: number,
        fetchCallback(currentIndex: number): any
    };
    onClose$ = new Subject();
    subscription: Subscription;
    modalRef: BsModalRef;
    addedRecordId$ = new Subject();
    currentKey: number;
    dataType: any = dataTypeEnum;

    constructor(readonly service: ExchangeRateScheduleService,
        private readonly cdRef: ChangeDetectorRef,
        private readonly ipxNotificationService: IpxNotificationService,
        readonly sbsModalRef: BsModalRef,
        readonly formBuilder: FormBuilder,
        private readonly navService: GridNavigationService,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutsService: IpxShortcutsService,
        private readonly renderer: Renderer2) {
    }

    ngOnInit(): void {
        this.form = this.createFormGroup();
        if (!this.isAdding) {
            this.canNavigate = true;
            this.getExchangeRateScheduleDetails(this.id);

            this.navData = {
                ...this.navService.getNavigationData(),
                fetchCallback: (currentIndex: number): any => {
                    return this.navService.fetchNext$(currentIndex).toPromise();
                }
            };
            const data = this.navData.keys.length === 1 ? this.navData.keys[0] : this.navData.keys.filter(x => Number(x.value) === this.id)[0];
            if (data) {
                this.currentKey = data.key;
            }
        } else {
            this.entry = new ExchangeRateScheduleItems();
        }
        this.handleShortcuts();
    }

    validateExchangeRateScheduleCode = (): any => {
        const value = this.form.controls.code.value;
        if (!value) { return; }
        this.form.patchValue({ code: value.toUpperCase() });

        this.service.validateExchangeRateScheduleCode(value).subscribe(res => {
            if (res) {
                this.form.controls.code.setErrors({ duplicateExchangeRateScheduleCode: true });
                this.cdRef.markForCheck();
            }
        });
    };

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.SAVE, (): void => { this.submit(); }],
            [RegisterableShortcuts.REVERT, (): void => { this.cancel(); }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    getExchangeRateScheduleDetails(id: number): any {
        if (id) {
            this.service.getExchangeRateScheduleDetails(id).subscribe((res: ExchangeRateScheduleRequest) => {
                if (res) {
                    this.setFormData(res);
                }
            });
        }
    }

    createFormGroup = (): FormGroup => {
        this.form = this.formBuilder.group({
            id: this.id,
            code: ['', Validators.compose([Validators.required, Validators.maxLength(20)])],
            description: ['', Validators.compose([Validators.required, Validators.maxLength(80)])]
        });

        return this.form;
    };

    setFormData(data: ExchangeRateScheduleRequest): any {
        this.form.setValue({
            id: data.id,
            code: data.code,
            description: data.description
        });
        this.cdRef.markForCheck();
    }

    getNextExchangeRateSchedule(next: number): void {
        this.id = next;
        this.getExchangeRateScheduleDetails(next);
    }

    submit(): void {
        if (this.form.valid && this.form.value && this.form.dirty) {
            this.service.submitExchangeRateSchedule(this.form.value).subscribe((res) => {
                if (res) {
                    this.addedRecordId$.next(res);
                    this.onClose$.next({ success: true });
                    this.form.setErrors(null);
                    this.sbsModalRef.hide();
                }
                this.cdRef.markForCheck();
            });
        }
    }

    cancel(): void {
        if (this.form.dirty) {
            const modal = this.ipxNotificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.resetForm();
                });
        } else {
            this.resetForm();
        }
    }

    resetForm = (): void => {
        this.form.reset();
        this.onClose$.next(false);
        this.sbsModalRef.hide();
    };

}
