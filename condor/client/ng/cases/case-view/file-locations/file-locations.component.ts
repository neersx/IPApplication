import { ChangeDetectionStrategy, Component, EventEmitter, OnInit } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { LocalSettings } from 'core/local-settings';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { MaintenanceTopicContract } from '../base/case-view-topics.base.component';
import { caseViewTopicTitles } from '../case-view-topic-titles';
import { FileHistoryComponent } from './file-history/file-history.component';
import { FileLocationsItems } from './file-locations.model';
import { FileLocationsService } from './file-locations.service';

@Component({
    selector: 'ipx-caseview-file-location',
    templateUrl: './file-locations.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class FileLocationsComponent implements OnInit, MaintenanceTopicContract {
    topic: Topic;
    isHosted: boolean;
    rowEditUpdates: { [rowKey: string]: any };
    formGroup: FormGroup;
    fileLocationWhenMoved: number;
    grid: any;
    permissions: FileLocationPermissions;

    constructor(readonly localSettings: LocalSettings,
        private readonly rootScopeService: RootScopeService,
        private readonly modalService: IpxModalService,
        private readonly service: FileLocationsService) { }

    ngOnInit(): void {
        this.isHosted = this.rootScopeService.isHosted;
        this.topic.hasChanges = false;
        this.rowEditUpdates = {};
        this.fileLocationWhenMoved = this.topic.params.viewData.fileLocationWhenMoved;
        this.permissions = this.getPermissions(this.topic.params.viewData);
        if (this.isHosted) {
            this.getCaseReference();
        }
    }

    getCaseReference(): void {
        this.service.getCaseReference(this.topic.params.viewData.caseKey).subscribe((res: string) => {
            this.topic.params.viewData.irn = res;
        });
    }

    openFileLocationHistory(): void {
        this.modalService.openModal(FileHistoryComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                topic: this.topic,
                isHosted: this.isHosted,
                permissions: this.permissions,
                fileHistoryFromMaintenance: false
            }
        });
    }

    private getPermissions(viewData: any): any {
        const permit: FileLocationPermissions = {
            CAN_MAINTAIN: viewData.canMaintainCase,
            CAN_CREATE_CASE: viewData.canCreateCaseFile,
            CAN_UPDATE: viewData.canUpdateCaseFile,
            CAN_DELETE: viewData.canDeleteCaseFile,
            WHEN_MOVED_SETTINGS: this.assignWhenMovedEnum(viewData.fileLocationWhenMoved),
            CAN_REQUEST_CASE_FILE: viewData.canRequestCaseFile,
            DEFAULT_USER_ID: viewData.nameId,
            DISPLAY_NAME: viewData.displayName
        };

        return permit;
    }

    private readonly assignWhenMovedEnum = (value: number): WhenMovedEnum => {
        switch (value) {
            case 1: return WhenMovedEnum.AllowDateButTimeDisabledWithCurrentTime;
            case 2: return WhenMovedEnum.DisabledDateAndTimeWithSystemDateButZeroTime;
            case 3: return WhenMovedEnum.DisabledDateAndTimeWithSystemDateTime;
            default: return WhenMovedEnum.AllowBothAndDateTime;
        }
    };

    gridChanged(event: any): any {
        this.grid = event;
    }

    getChanges = (): { [key: string]: any; } => {
        const data = { fileLocations: { rows: [] } };
        const keys = Object.keys(this.grid.rowEditFormGroups);
        keys.forEach((r) => {
            let value: FileLocationsItems = this.grid.rowEditFormGroups[r].value;
            if (value.status === rowStatus.deleting) {
                value = this.service.formatFileLocation(value);
            }
            data.fileLocations.rows.push(value);
        });

        return data;
    };

    onError = (): void => {
        if (this.topic.setErrors) {
            this.topic.setErrors(true);
        }
    };
}

export class CaseFileLocationsTopic extends Topic {
    readonly key = 'fileLocations';
    readonly title = caseViewTopicTitles.fileLocations;
    readonly component = FileLocationsComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: TopicParam) {
        super();
    }
}

export enum WhenMovedEnum {
    AllowBothAndDateTime = 0,
    AllowDateButTimeDisabledWithCurrentTime = 1,
    DisabledDateAndTimeWithSystemDateButZeroTime = 2,
    DisabledDateAndTimeWithSystemDateTime = 3
}

export class FileLocationPermissions {
    CAN_MAINTAIN: boolean;
    CAN_CREATE_CASE: boolean;
    CAN_UPDATE: boolean;
    CAN_DELETE: boolean;
    WHEN_MOVED_SETTINGS: WhenMovedEnum;
    CAN_REQUEST_CASE_FILE: boolean;
    DEFAULT_USER_ID: number;
    DISPLAY_NAME: string;
}