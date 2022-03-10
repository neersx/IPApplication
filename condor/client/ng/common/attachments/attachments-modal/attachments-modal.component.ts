import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { DmsTopic } from 'common/case-name/dms/dms.component';
import { AppContextService } from 'core/app-context.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable, Subject } from 'rxjs';

@Component({
    selector: 'app-attachments-modal',
    templateUrl: './attachments-modal.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class AttachmentsModalComponent implements OnInit {
    @Input() baseType: 'case' | 'name' | 'activity' | 'priorArt';
    @Input() key: any;
    @Input() eventDetails: any;
    @Input() viewData$: Observable<any>;
    @Input() headerData: { label: string, value: string };
    dmsConfigured = false;
    attachmentsVisible = false;
    topic: DmsTopic;
    dataModified$ = new Subject();
    dataModified = false;
    case: { key: number };
    showDms: boolean;
    viewData = { isExternal: false, canMaintainAttachment: { canAdd: false, canEdit: false, canDelete: false }, baseType: null, key: null };
    loaded = false;

    constructor(readonly appContext: AppContextService, readonly bsModalRef: BsModalRef, private readonly cdRef: ChangeDetectorRef) { }

    ngOnInit(): void {
        this.loaded = false;
        this.appContext.appContext$.subscribe(
            context => {
                this.viewData.isExternal = context.user.isExternal;
            });

        this.viewData.baseType = this.baseType;
        this.viewData.key = this.baseType === 'case' ? this.key : (this.baseType === 'priorArt' ? this.key.sourceId : null);
        this.case = {
            key: this.baseType === 'case' ? this.key : (this.baseType === 'priorArt' ? this.key.caseKey : null)
        };
        this.topic = new DmsTopic({
            callerType: 'CaseView',
            viewData: {
                caseKey: this.baseType === 'case' ? this.key : (this.baseType === 'priorArt' ? this.key.caseKey : null)
            }
        });

        this.viewData$.subscribe((permissions: any) => {
            this.viewData.canMaintainAttachment = this.baseType === 'case' ? permissions.canMaintainCaseAttachments : this.baseType === 'priorArt' ? permissions.canMaintainPriorArtAttachments : { canAdd: false, canEdit: false, canDelete: false };
            this.dmsConfigured = permissions.canAccessDocumentsFromDms && this.baseType === 'case';
            this.attachmentsVisible = permissions.canViewCaseAttachments;
            this.showDms = this.dmsConfigured && !this.attachmentsVisible;
            this.loaded = true;
            this.cdRef.detectChanges();
        });
    }

    close(): void {
        this.dataModified$.next(this.dataModified);
        this.bsModalRef.hide();
    }
}