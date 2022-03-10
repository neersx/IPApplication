import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, Observable, Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { AttachmentMaintenanceFormComponent } from './attachment-maintenance-form/attachment-maintenance-form.component';

@Component({
    selector: 'ipx-attachment-maintenance',
    templateUrl: './attachment-maintenance.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class AttachmentMaintenanceComponent implements OnInit {
    @Input() activityAttachment: any;
    @Input() activityDetails: any;
    @Input() viewData: any;

    @ViewChild('maintenanceForm') maintenanceForm: AttachmentMaintenanceFormComponent;

    id: number;
    baseType: string;
    data: any;
    hasValidChanges$ = new BehaviorSubject(null);
    hasSavedChanges = false;
    onClose$ = new Subject();
    confirmationMessage: string;
    currentDate: Date;
    hasSettings = true;
    isAdding = false;
    isHosted = false;
    constructor(readonly cdr: ChangeDetectorRef,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutService: IpxShortcutsService,
        private readonly rootScopeService: RootScopeService,
        private readonly modal: BsModalRef
    ) {
        this.currentDate = new Date();
    }

    ngOnInit(): void {
        this.id = this.viewData.id;
        this.baseType = this.viewData.baseType;
        this.hasSettings = this.viewData.hasAttachmentSettings;

        this.isHosted = this.rootScopeService.isHosted;
        this.isAdding = this.activityAttachment ? false : true;
        this.setDerivedBaseType();
        this.handleShortcuts();
    }

    setDerivedBaseType(): void {
        if (this.baseType === 'activity') {
            if (!_.isNumber(this.id)) {
                if (_.isNumber(this.activityDetails.activityCaseId)) {
                    this.id = this.activityDetails.activityCaseId;
                    this.baseType = 'case';
                }
                if (_.isNumber(this.activityDetails.activityNameId)) {
                    this.id = this.activityDetails.activityNameId;
                    this.baseType = 'name';
                }
                if (_.isNumber(this.viewData.priorArtId)) {
                    this.id = this.viewData.priorArtId;
                    this.baseType = 'priorArt';
                }
            }
        }
    }
    save = (): void => {
        this.maintenanceForm.save();
    };
    revert = (): void => {
        this.maintenanceForm.revert();
    };
    close = (event: any): void => {
        this.modal.hide();
        this.onClose$.next(event != null || this.hasSavedChanges);
    };
    readonly subscribeChanges = (value: any) => {
        if (value !== this.hasValidChanges$.getValue()) {
            this.hasValidChanges$.next(value);
        }
    };
    readonly subscribeSavedChanges = (value: any) => {
        this.hasSavedChanges = this.hasSavedChanges || value;
    };

    deleteAttachment(): void {
        this.maintenanceForm.deleteAttachment();
    }

    private handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.REVERT, (): void => { if (this.hasValidChanges$.getValue() !== null) { this.revert(); } }],
            [RegisterableShortcuts.SAVE, (): void => { if (this.hasValidChanges$.getValue() === true) { this.save(); } }]]);

        this.shortcutService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }
}
