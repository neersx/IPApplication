import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnDestroy, OnInit, Output, ViewChild } from '@angular/core';
import { UserInfoService } from 'accounting/time-recording/settings/user-info.service';
import { LocalSettings } from 'core/local-settings';
import { ReplaySubject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { DateFunctions } from 'shared/utilities/date-functions';
import { PostTimeService } from '../post-time.service';
import { TimeSettingsService } from './../../settings/time-settings.service';

@Component({
    selector: 'post-selected',
    templateUrl: 'post-selected.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class PostSelectedComponent implements OnInit, AfterViewInit, OnDestroy {
    gridOptions: IpxGridOptions;
    @ViewChild('ipxTimePostingGridRef', { static: true }) _grid: IpxKendoGridComponent;
    displaySeconds: boolean;
    staffNameId?: number;
    destroy$: ReplaySubject<any> = new ReplaySubject<any>(1);
    @Input() fromDate: Date;
    @Input() toDate: Date;
    @Input() postAllStaff: boolean;
    @Output() readonly recordsSelected = new EventEmitter<boolean>();

    constructor(private readonly postTimeService: PostTimeService,
        private readonly cdRef: ChangeDetectorRef,
        private readonly settingsService: TimeSettingsService,
        private readonly localSettings: LocalSettings,
        private readonly userInfoService: UserInfoService) {
        this.displaySeconds = this.settingsService.displaySeconds;
    }

    ngOnDestroy(): void {
        this.destroy$.next(null);
        this.destroy$.complete();
    }

    ngOnInit(): void {
        this.userInfoService.userDetails$
            .pipe(takeUntil(this.destroy$))
            .subscribe((userInfo) => {
                this.staffNameId = userInfo.staffId;
                this.gridOptions = this._buildGridOptions();
            });
    }

    ngAfterViewInit(): void {
        this.recordsSelected.next(false);
    }

    _buildGridOptions(): IpxGridOptions {
        let pageSize: number;
        const pageSizeSetting = this.localSettings.keys.accounting.timesheet.posting.pageSize;
        if (pageSizeSetting) {
            pageSize = pageSizeSetting.getLocal;
        }

        return {
            autobind: true,
            columnPicker: false,
            filterable: false,
            selectable: {
                mode: 'multiple',
                checkboxOnly: true,
                enabled: true
            },
            sortable: true,
            pageable: { pageSize, pageSizeSetting },
            read$: (q) => this.postTimeService.getDates(q, this.staffNameId, this.fromDate, this.toDate, this.postAllStaff),
            columns: this._getColumns(),
            persistSelection: true,
            selectedRecords: {
                rows: {
                    rowKeyField: 'rowKey',
                    selectedKeys: [],
                    selectedRecords: []
                }
            }
        };
    }

    _getColumns = (): Array<GridColumnDefinition> => [
        {
            title: 'accounting.time.postTime.date',
            field: 'date',
            template: true,
            sortable: true
        },
        {
            title: 'accounting.time.postTime.hours',
            field: 'totalTimeInSeconds',
            template: true,
            sortable: true
        },
        {
            title: 'accounting.time.postTime.chargeableHours',
            field: 'totalChargableTimeInSeconds',
            template: true,
            sortable: true
        },
        {
            title: 'accounting.time.postTime.staffName',
            field: 'staffName',
            hidden: !this.postAllStaff,
            sortable: true
        }
    ];

    onRowSelectionChanged(): void {
        this.recordsSelected.next(this._grid ? (this._grid.getRowSelectionParams().allSelectedItems.length ? true : false) : false);
        this.cdRef.detectChanges();
    }

    getSelectedDates(): Array<any> {
        return this._grid && this._grid.getRowSelectionParams().allSelectedItems
            ? this._grid.getRowSelectionParams().allSelectedItems.map((item) => {
                return { date: DateFunctions.toLocalDate(new Date(item.date), true), staffNameId: item.staffNameId };
            }) : null;
    }
}
