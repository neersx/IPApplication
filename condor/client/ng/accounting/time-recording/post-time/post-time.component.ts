import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable } from 'rxjs';
import { take, tap } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as _ from 'underscore';
import { UserInfoService } from '../settings/user-info.service';
import { TimeSettingsService } from './../settings/time-settings.service';
import { PostEntryDetails, UserIdAndPermissions } from './../time-recording-model';
import { PostSelectedComponent } from './post-selected/post-selected.component';
import { PostResult, PostTimeView } from './post-time.model';
import { PostTimeService } from './post-time.service';

@Component({
    selector: 'post-time',
    templateUrl: 'post-time.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class PostTimeComponent implements OnInit, AfterViewInit {
    @Input() postEntryDetails: PostEntryDetails = null;
    @ViewChild('postSelectedRef', { static: false }) _postSelectedRef: PostSelectedComponent;
    @Output() readonly postInitiated = new EventEmitter<boolean>();
    selectedEntity: any;
    selectedEntityKey: number;
    isEntityDisabled: boolean;
    isEntityHidden: boolean;
    postableDates: Array<{ date: Date, totalTime: number, chargeableTime: number }> = [];
    gridOptions: IpxGridOptions;
    displaySeconds: boolean;
    selectedPostType: string;
    disablePost: boolean;
    postAllStaff: boolean;
    staffNameId?: number;
    canPostForAllStaff: boolean;
    currentDate: Date;
    postAllStaffFromDate: Date;
    postAllStaffToDate: Date;
    view$: Observable<PostTimeView>;
    userInfo$: Observable<UserIdAndPermissions>;
    areRecordsSelected: boolean;
    tomorrow = new Date();

    constructor(
        private bsModalRef: BsModalRef,
        private readonly postTimeService: PostTimeService,
        private readonly cdRef: ChangeDetectorRef,
        private readonly settingsService: TimeSettingsService,
        readonly userInfoService: UserInfoService
    ) {
        this.displaySeconds = this.settingsService.displaySeconds;
    }

    ngOnInit(): void {
        this.view$ = this.postTimeService.getView()
            .pipe(tap((r: PostTimeView) => {
                if (!!r.entities && r.entities.length > 0) {
                    this.selectedEntity = (r.entities.length > 1) ? r.entities.find(e => e.isDefault) || r.entities[0] : r.entities[0];
                    this.selectedEntityKey = this.selectedEntity.id;
                    if (this.postEntryDetails) {
                        this.postEntryDetails.entityKey = this.selectedEntityKey;
                    }
                }
                this.isEntityDisabled = r.hasFixedEntity;
                this.isEntityHidden = r.postToCaseOfficeEntity;
            }));
        this.userInfo$ = this.userInfoService.userDetails$
            .pipe(tap((details: UserIdAndPermissions) => {
                this.staffNameId = details.staffId;
            }));
    }

    ngAfterViewInit(): void {
        if (this.canPostForAllStaff) {
            this.tomorrow.setDate(DateFunctions.toLocalDate(new Date(), true).getDate() + 1);
            this.postAllStaffFromDate = DateFunctions.toLocalDate(this.currentDate, true);
            this.postAllStaffToDate = DateFunctions.toLocalDate(this.currentDate, true);
            this.postAllStaff = false;
        }
        this.selectedPostType = '0';
        this.cdRef.markForCheck();
    }

    postTime = (): void => {
        const datesToPost = (this.selectedPostType === '1') ? this._postSelectedRef.getSelectedDates() : null;
        if (datesToPost != null && datesToPost.length === 0) {
            return;
        }
        if (this.postAllStaff) {
            this.postTimeService.postForAllStaff(this.selectedEntityKey, datesToPost, this.postAllStaffFromDate, this.postAllStaffToDate);
            this.postInitiated.next(true);
        } else if (this.postEntryDetails) {
            this.postTimeService.postSelectedEntry(this.postEntryDetails);
            this.postInitiated.next(true);
            this.bsModalRef.hide();
        } else {
            this.postTimeService.postTime(this.selectedEntityKey, datesToPost, _.isNumber(this.staffNameId) ? this.staffNameId : null);
            this.postInitiated.next(true);
        }
        this.postTimeService.postResult$.pipe(take(1)).subscribe((result: PostResult) => {
            if (!!result.rowsPosted && !!this._postSelectedRef) {
                this._postSelectedRef._grid.search();
            }
            if (!!result.isBackground) {
                this.bsModalRef.hide();
            }
        });
    };

    onEntityChange(event: number): void {
        this.selectedEntityKey = event;
        if (!!this.postEntryDetails) {
            this.postEntryDetails.entityKey = this.selectedEntityKey;
        }
    }

    cancel(): void {
        this.bsModalRef.hide();
        this.bsModalRef = null;
    }

    recordSelectionChanged(recordsSelected: boolean): void {
        this.areRecordsSelected = recordsSelected;
        this.cdRef.detectChanges();
    }

    changeDate(date: any): void {
        if (!!this.postAllStaffFromDate && !!this.postAllStaffToDate &&
            (this.postAllStaffFromDate <= this.postAllStaffToDate) &&
            (this.postAllStaffFromDate < this.tomorrow && this.postAllStaffToDate < this.tomorrow)) {
            this._postSelectedRef._grid.search();
        }
    }
}
