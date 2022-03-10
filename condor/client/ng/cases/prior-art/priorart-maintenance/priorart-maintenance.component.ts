import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/core';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Hotkey, HotkeysService } from 'angular2-hotkeys';
import { AttachmentModalService } from 'common/attachments/attachment-modal.service';
import { PageTitleService } from 'core/page-title.service';
import { QuickNavModel, RightBarNavService } from 'rightbarnav/rightbarnav.service';
import { takeWhile } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { PriorArtType } from '../priorart-model';
import { PriorArtMultistepComponent } from '../priorart-multistep/priorart-multistep.component';
import { PriorArtService } from '../priorart.service';
import { PriorartCreateSourceComponent } from './create-source/priorart-create-source.component';
import { PriorartMaintenanceHelper } from './priorart-maintenance-helper';

@Component({
    selector: 'ipx-priorart-maintenance',
    templateUrl: './priorart-maintenance.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class PriorArtMaintenanceComponent implements OnInit, AfterViewInit {
    @ViewChild('multiStep', { static: false }) priorArtSteps: PriorArtMultistepComponent;
    @ViewChild('step1', { static: false }) dataDetailComponent: PriorartCreateSourceComponent;
    source: any;
    caseIrn: any;
    priorArtSourceTableCodes: any;
    @Input() priorArtData: any;
    @Input() stateParams: any;
    @Input() translationsList: any = {};
    formGroup: FormGroup;
    originalSourceData: any;
    deleteSuccess = false;
    constructor(private readonly priorArtService: PriorArtService,
        private readonly cdr: ChangeDetectorRef,
        public hotKeysService: HotkeysService,
        private readonly ipxNotificationService: IpxNotificationService,
        readonly notificationService: NotificationService,
        readonly stateService: StateService,
        readonly translate: TranslateService,
        readonly dateHelper: DateHelper,
        private readonly pageTitleService: PageTitleService,
        private readonly priorArtHelper: PriorartMaintenanceHelper,
        public rightBarNavService: RightBarNavService,
        private readonly attachmentModalService: AttachmentModalService
    ) { }

    ngOnInit(): void {
        const hotkeys = [
            new Hotkey(
                'alt+shift+s',
                (event, combo): boolean => {
                    if (this.isSaveButtonEnabled()) {
                        this.save();
                    }

                    return false;
                }, undefined, 'shortcuts.save'),
            new Hotkey(
                'alt+shift+z',
                (event, combo): boolean => {
                    this.revert();

                    return false;
                }, undefined, 'shortcuts.revert')
        ];
        this.hotKeysService.add(hotkeys);
        this.priorArtSourceTableCodes = this.priorArtData.priorArtSourceTableCodes;
        this.caseIrn = this.priorArtData.caseIrn;
        this.buildSourceDescription(this.priorArtData.sourceDocumentData);
        this.cdr.markForCheck();
        this.setContextNavigation();
    }

    ngAfterViewInit(): void {
        if (this.stateService.params.goToStep) {
            this.priorArtSteps.goTo(this.stateService.params.goToStep);
        }
    }

    buildSourceDescription = (sourceDocumentData: any) => {
        this.originalSourceData = { ...sourceDocumentData };
        this.originalSourceData.translationType = (this.originalSourceData.translationType && sourceDocumentData.translationType.key) ? sourceDocumentData.translationType.key : null;
        this.originalSourceData.reportIssued = sourceDocumentData && sourceDocumentData.reportIssued ? new Date(this.dateHelper.toLocal(sourceDocumentData.reportIssued)) : null;
        this.originalSourceData.reportReceived = sourceDocumentData && sourceDocumentData.reportReceived ? new Date(this.dateHelper.toLocal(sourceDocumentData.reportReceived)) : null;
        this.originalSourceData.applicationFiledDate = sourceDocumentData && sourceDocumentData.applicationFiledDate ? new Date(this.dateHelper.toLocal(sourceDocumentData.applicationFiledDate)) : null;
        this.originalSourceData.publishedDate = sourceDocumentData && sourceDocumentData.publishedDate ? new Date(this.dateHelper.toLocal(sourceDocumentData.publishedDate)) : null;
        this.originalSourceData.grantedDate = sourceDocumentData && sourceDocumentData.grantedDate ? new Date(this.dateHelper.toLocal(sourceDocumentData.grantedDate)) : null;
        this.originalSourceData.priorityDate = sourceDocumentData && sourceDocumentData.priorityDate ? new Date(this.dateHelper.toLocal(sourceDocumentData.priorityDate)) : null;
        this.originalSourceData.ptoCitedDate = sourceDocumentData && sourceDocumentData.ptoCitedDate ? new Date(this.dateHelper.toLocal(sourceDocumentData.ptoCitedDate)) : null;
        if (!!sourceDocumentData) {
            this.source = this.priorArtHelper.buildDescription(sourceDocumentData);
            this.pageTitleService.setPrefix(this.priorArtHelper.buildShortDescription(sourceDocumentData));
        } else {
            this.pageTitleService.setPrefix(this.translate.instant('priorart.maintenance.step1.newSourceTitle'));
        }
    };

    save = () => {
        const data = {
            createSource: {
                ignoreDuplicates: false,
                sourceDocument: this.dataDetailComponent.getData()
            }
        };
        const priorArtType = this.dataDetailComponent.selectedPriorArtType;
        this.priorArtService.maintainPriorArt$(data, this.stateParams.caseKey, priorArtType).subscribe((response: any) => {
            const success = response.savedSuccessfully;
            if (!success) {
                if (response.matchingSourceDocumentExists) {
                    // tslint:disable-next-line: strict-boolean-expressions
                    let description: string = data.createSource.sourceDocument.description || '';
                    if (description) {
                        description = ', (' + description + ')';
                        if (description.length > 100) {
                            description = description.substr(0, 100) + '...)';
                        }
                    }
                    let jurisdictionDescription = '';
                    if (data.createSource.sourceDocument.issuingJurisdiction) {
                        jurisdictionDescription = ', ' + data.createSource.sourceDocument.issuingJurisdiction.code;
                    }
                    const messageParams = {
                        jurisdiction: jurisdictionDescription,
                        // tslint:disable-next-line: strict-boolean-expressions
                        sourceType: this.dataDetailComponent.formGroup.value.sourceType.name || '',
                        description
                    };
                    const notificationRef = this.ipxNotificationService.openConfirmationModal('priorart.maintenance.step1.matchingSourceDocumentHeading', 'priorart.maintenance.step1.matchingSourceDocument', 'Proceed', 'Cancel', null, messageParams);
                    notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
                        .subscribe((option) => {
                            data.createSource.ignoreDuplicates = true;
                            this.priorArtService.maintainPriorArt$(data, this.stateParams.caseKey, priorArtType).subscribe((secondResponse: any) => {
                                const confirmedSuccess = secondResponse.savedSuccessfully;
                                if (confirmedSuccess) {
                                    this.notificationService.success();
                                    this.dataDetailComponent.markAsPristine();
                                    this.cdr.detectChanges();
                                    this.stateService.go('referenceManagement', { priorartId: secondResponse.id, caseKey: this.stateParams.caseKey }, {
                                        reload: true
                                    });
                                }
                            });
                        });
                }
            } else {

                if (this.getPriorArtType() === PriorArtType.NewSource) {
                    this.buildSourceDescription({
                        sourceType: this.dataDetailComponent.formGroup.value.sourceType,
                        issuingJurisdiction: this.dataDetailComponent.formGroup.value.issuingJurisdiction,
                        description: this.dataDetailComponent.formGroup.value.description
                    });
                }
                this.notificationService.success();
                this.dataDetailComponent.markAsPristine();
                this.cdr.detectChanges();
                this.stateService.go('referenceManagement', { priorartId: response.id, caseKey: this.stateParams.caseKey }, {
                    reload: true
                });
            }
        });
    };

    revert = () => {
        this.dataDetailComponent.formGroup.reset(this.originalSourceData);
        this.cdr.markForCheck();
    };

    isPageDirty = (): boolean => {
        return this.dataDetailComponent && this.dataDetailComponent.formGroup.dirty;
    };

    isSaveButtonEnabled = (): boolean => {
        return this.dataDetailComponent && this.dataDetailComponent.formGroup.dirty && this.dataDetailComponent.formGroup.valid;
    };

    getPriorArtType = (): PriorArtType => {
        if (!this.priorArtData.sourceDocumentData) {
            return PriorArtType.NewSource;
        }
        if (this.priorArtData.sourceDocumentData.isSourceDocument && !this.priorArtData.sourceDocumentData.isIpDocument) {
            return PriorArtType.Source;
        } else if (!this.priorArtData.sourceDocumentData.isSourceDocument && !!this.priorArtData.sourceDocumentData.isIpDocument) {
            return PriorArtType.Ipo;
        } else if (!this.priorArtData.sourceDocumentData.isSourceDocument && !this.priorArtData.sourceDocumentData.isIpDocument) {
            return PriorArtType.Literature;
        }
    };

    isSourceType = (): boolean => {
        if (this.getPriorArtType() === PriorArtType.Source || this.getPriorArtType() === PriorArtType.NewSource) {
            return true;
        }

        return false;
    };

    delete = (): void => {
        const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('priorart.maintenance.confirmDelete');
        notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
        .subscribe(() => {
            this.priorArtService.deletePriorArt$(this.stateParams.sourceId)
            .subscribe((response: any) => {
                if (response.result) {
                    this.notificationService.success();
                    this.dataDetailComponent.formGroup.reset();
                    this.caseIrn = null;
                    this.source = null;
                    this.deleteSuccess = true;
                    this.dataDetailComponent.formGroup.disable();
                }
            });
        });
    };

    private readonly setContextNavigation = () => {
        const context: any = {};
        if (this.priorArtData.canViewAttachment && !!this.stateParams.sourceId) {
            context.contextAttachments = new QuickNavModel(null, {
                id: 'contextAttachments',
                icon: 'cpa-icon-paperclip',
                tooltip: 'priorart.contextNavigationTooltip.attachments',
                click: () => {
                    this.attachmentModalService.displayAttachmentModal('priorArt', this.stateParams, {}, { label: this.priorArtData.sourceDocumentData.isSourceDocument ? 'priorart.sourceSubHeader' : 'priorart.priorArtSubHeader', value: this.priorArtHelper.buildDescription(this.priorArtData.sourceDocumentData) });
                }
            });
        }
        this.rightBarNavService.registercontextuals(context);
    };
}