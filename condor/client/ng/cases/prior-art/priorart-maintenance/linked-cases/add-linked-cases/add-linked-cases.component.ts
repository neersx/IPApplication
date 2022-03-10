import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { PriorArtService } from 'cases/prior-art/priorart.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import * as _ from 'underscore';
import { PriorartMaintenanceHelper } from '../../priorart-maintenance-helper';

@Component({
    selector: 'ipx-add-linked-cases',
    templateUrl: './add-linked-cases.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class AddLinkedCasesComponent implements OnInit, OnDestroy {
    sourceData: any;
    title: string;
    destroy$ = new Subject<boolean>();
    formGroup: FormGroup;
    success$ = new Subject<boolean>();
    addAnother: boolean | false;
    invokedFromCases: boolean | false;
    allowIndirectLinks: boolean;

    @ViewChild('caseReference', { static: false }) caseReferenceEl: any;
    @ViewChild('caseFamily', { static: false }) caseFamilyEl: any;
    @ViewChild('caseList', { static: false }) caseListEl: any;
    @ViewChild('caseName', { static: false }) caseNameEl: any;

    get caseReference(): AbstractControl {
        return this.formGroup.controls.caseReference;
    }
    get caseFamily(): AbstractControl {
        return this.formGroup.controls.caseFamily;
    }
    get caseLists(): AbstractControl {
        return this.formGroup.controls.caseLists;
    }
    get caseName(): AbstractControl {
        return this.formGroup.controls.caseName;
    }
    get nameType(): AbstractControl {
        return this.formGroup.controls.nameType;
    }

    constructor(private readonly bsModalRef: BsModalRef, private readonly maintenanceHelper: PriorartMaintenanceHelper, private readonly formBuilder: FormBuilder, private readonly notificationService: NotificationService,
        private readonly priorArtService: PriorArtService, private readonly translateService: TranslateService, private readonly cdRef: ChangeDetectorRef) { }

    ngOnInit(): void {
        this.title = this.maintenanceHelper.buildDescription(this.sourceData);
        this.formGroup = this.formBuilder.group({
            caseReference: new FormControl(),
            caseFamily: new FormControl(),
            caseLists: new FormControl(),
            caseName: new FormControl(),
            nameType: new FormControl()
        });
        this.allowIndirectLinks = !this.invokedFromCases || (this.invokedFromCases && !this.sourceData.isSourceDocument);
    }

    isDisableNameType(): boolean {
        return !this.caseName.value;
    }

    onSave(): void {
        this.formGroup.clearValidators();
        const request = {
            sourceDocumentId: this.sourceData.sourceId,
            caseKey: !!this.caseReference.value ? this.caseReference.value.key : null,
            caseFamilyKey: !!this.caseFamily.value ? this.caseFamily.value.key : null,
            caseListKey: !!this.caseLists.value ? this.caseLists.value.key : null,
            nameKey: !!this.caseName.value ? this.caseName.value.key : null,
            nameTypeKey: !!this.nameType.value ? this.nameType.value.code : null
        };
        this.priorArtService.createLinkedCases$(request).pipe().subscribe((response: any) => {
            if (response.isSuccessful) {
                this.notificationService.success();
                this.success$.next(true);
                if (!this.addAnother) {
                    this.bsModalRef.hide();
                } else {
                    this.formGroup.reset();
                }
            } else {
                if (response.caseReferenceExists || response.isFamilyExisting || response.isCaseListExisting || response.isNameExisting) {
                    const errorParam =
                    [response.caseReferenceExists ? this.translateService.instant('priorart.maintenance.step3.linkedCases.messages.case', { case: this.caseReference.value.code }) : null,
                    response.isFamilyExisting ? this.translateService.instant('priorart.maintenance.step3.linkedCases.messages.family', { family: this.caseFamily.value.value }) : null,
                    response.isCaseListExisting ? this.translateService.instant('priorart.maintenance.step3.linkedCases.messages.caseList', { caseList: this.caseLists.value.value }) : null,
                    response.isNameExisting ? this.translateService.instant('priorart.maintenance.step3.linkedCases.messages.name', { name: this.caseName.value.displayName }) : null]
                        .filter(x => x && x.trim() !== '').join('');
                    const error = this.translateService.instant('priorart.maintenance.step3.linkedCases.messages.caseAlreadyLinked', { errorParam });
                    this.notificationService.alert({ message: error });
                    setTimeout(() => {
                        if (response.isCaseListExisting) {
                            this.caseLists.setErrors({ 'priorArt.alreadyLinked': true });
                            this.caseListEl.el.nativeElement.querySelector('input').focus();
                        }
                        if (response.isFamilyExisting) {
                            this.caseFamily.setErrors({ 'priorArt.alreadyLinked': true });
                            this.caseFamilyEl.el.nativeElement.querySelector('input').focus();
                        }
                        if (response.caseReferenceExists) {
                            this.caseReference.setErrors({ 'priorArt.alreadyLinked': true });
                            this.caseReferenceEl.el.nativeElement.querySelector('input').focus();
                        }
                        if (response.isNameExisting) {
                            this.caseName.setErrors({ 'priorArt.alreadyLinked': true });
                            this.caseNameEl.el.nativeElement.querySelector('input').focus();
                        }
                        this.cdRef.detectChanges();
                    }, 1000);
                } else {
                    this.notificationService.alert(null);
                }
            }
        });
    }

    cancel(): void {
        this.bsModalRef.hide();
    }

    ngOnDestroy(): void {
        this.destroy$.next(true);
        this.destroy$.complete();
    }

    isSaveEnabled(): boolean {
        return (!!this.caseReference.value || !!this.caseFamily.value || !!this.caseLists.value || !!this.caseName.value) && this.formGroup.valid;
    }
}
