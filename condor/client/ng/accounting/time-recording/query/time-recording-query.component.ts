import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, NgZone, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { ColumnComponent } from '@progress/kendo-angular-grid';
import { StateService } from '@uirouter/core';
import { TimeRecordingHelper } from 'accounting/time-recording-widget/time-recording-helper';
import { WarningCheckerService } from 'accounting/warnings/warning-checker.service';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { AppContextService } from 'core/app-context.service';
import { MessageBroker } from 'core/message-broker';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { KotViewForEnum } from 'rightbarnav/keep-on-top-notes-view.service';
import { BehaviorSubject, iif, ReplaySubject, Subject } from 'rxjs';
import { race } from 'rxjs/index';
import { debounceTime, distinctUntilChanged, filter, map, shareReplay, take, takeLast, takeUntil, takeWhile, tap } from 'rxjs/operators';
import { ContentStatus } from 'search/results/export.content.model';
import { ReportExportFormat } from 'search/results/report-export.format';
import { SearchExportService } from 'search/results/search-export.service';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxDatePickerComponent } from 'shared/component/forms/ipx-date-picker/ipx-date-picker.component';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { FileDownloadService } from 'shared/shared-services/file-download.service';
import * as _ from 'underscore';
import { PostTimeDialogService } from '../post-time/post-time-dialog.service';
import { TimeSettingsService } from '../settings/time-settings.service';
import { UserInfoService } from '../settings/user-info.service';
import { PostEntryDetails, TimeEntryEx, TimeRecordingPermissions, UserIdAndPermissions } from '../time-recording-model';
import { LocalSettings, TimeRecordingService } from '../time-recording.namespace';
import { BatchSelectionDetails, ReverseSelection, TimeRecordingQueryData, TimeSearchPeriods, TimeSearchQuery } from './time-recording-query-model';
import { TimeSearchService } from './time-search.service';
import { UpdateNarrativeComponent } from './update-narrative/update-narrative.component';

@Component({
    selector: 'time-recording-query',
    templateUrl: './time-recording-query.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    styleUrls: ['./time-recording-query.component.scss'],
    animations: [
        slideInOutVisible
    ],
    providers: [PostTimeDialogService]
})
export class TimeRecordingQueryComponent implements OnInit, OnDestroy, AfterViewInit {
    @Input() entities: Array<{ id: number, displayName: string, isDefault: boolean }>;
    @ViewChild('searchResultsGrid', { static: true }) searchResultsGrid: IpxKendoGridComponent;
    @ViewChild('searchForm', { static: false }) searchForm: NgForm;
    formData: TimeRecordingQueryData;
    defaultStaffName: string;
    defaultStaffNameId: number;
    showSearchBar = true;
    isFromTimeRecording = true;
    searchGridOptions: IpxGridOptions;
    queryParams: any;
    showWebLinks = false;
    searchParams = new TimeSearchParameters();
    timeSummary: TimeSummary;
    displaySeconds: boolean;

    bulkActions: Array<IpxBulkActionOptions>;
    bindings: Array<any>;
    exportContentBinding: string;
    exportContentTypeMapper: Array<any>;
    dwnlContentSubscription: any;
    dwlContentId$: any;
    bgContentSubscription: any;
    bgContentId$: any;
    _hasSearchBeenRun = new Subject<boolean>();
    selectedStaff: any;
    _userPermissions = new TimeRecordingPermissions();
    _hasRowSelection = new BehaviorSubject<boolean>(false);
    _hasSingleRowSelection = new BehaviorSubject<boolean>(false);
    _singleEntrySelected: TimeEntryEx;
    postingStaff: any;
    modalRef: BsModalRef;
    _isNewSearch = false;
    destroy$: ReplaySubject<any> = new ReplaySubject<any>(1);
    caseKey$ = new BehaviorSubject<string>('');
    periods: Array<TimeSearchPeriods>;
    constructor(
        private readonly stateService: StateService,
        private readonly settingsService: TimeSettingsService,
        private readonly cdRef: ChangeDetectorRef,
        readonly searchService: TimeSearchService,
        private readonly appContextService: AppContextService,
        readonly localSettings: LocalSettings,
        private readonly userInfoService: UserInfoService,
        private readonly translate: TranslateService,
        private readonly messageBroker: MessageBroker,
        private readonly searchExportService: SearchExportService,
        private readonly zone: NgZone,
        private readonly fileDownloadService: FileDownloadService,
        private readonly notificationService: NotificationService,
        private readonly timeService: TimeRecordingService,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly postTimeDialog: PostTimeDialogService,
        private readonly modalService: IpxModalService,
        private readonly dateHelper: DateHelper,
        private readonly warningChecker: WarningCheckerService) {
        this.bindings = [];
        this.exportContentBinding = 'export.content';
        this.exportContentTypeMapper = [];
    }

    ngAfterViewInit(): void {
        this.searchForm.form.statusChanges
            .pipe(takeUntil(this.destroy$), distinctUntilChanged())
            .subscribe(() => {
                this.cdRef.detectChanges();
            });
    }

    ngOnInit(): void {
        this.isFromTimeRecording = !!this.stateService.params.entryDate;
        this._initialiseFormData();

        this.searchService.searchParamData$()
            .pipe(take(1))
            .subscribe((response: any) => {
                this.searchParams.entities = response.entities;
                this.displaySeconds = response.settings.displaySeconds;
                if (!this.isFromTimeRecording) {
                    this.defaultStaffName = response.userInfo.displayName;
                    this.defaultStaffNameId = response.userInfo.nameId;
                    this.formData.staff = { key: this.defaultStaffNameId, displayName: this.defaultStaffName };
                    this.selectedStaff = { staffNameId: this.defaultStaffNameId, displayName: this.defaultStaffName };
                    this.timeService.getUserPermissions(this.defaultStaffNameId)
                        .pipe(takeLast(1), takeUntil(this.destroy$))
                        .subscribe(this.onPermissionsRecieved.bind(this));
                }
                this.cdRef.detectChanges();
            });

        if (this.isFromTimeRecording) {
            this.userInfoService.userDetails$.pipe(take(1)).subscribe((userInfo) => {
                this.defaultStaffName = userInfo.displayName;
                this.defaultStaffNameId = userInfo.staffId;
                this.formData.staff = { key: this.defaultStaffNameId, displayName: this.defaultStaffName };
            });
            this.displaySeconds = this.settingsService.displaySeconds;
        }

        this.appContextService.appContext$.subscribe(v => {
            this.showWebLinks = (v.user ? v.user.permissions.canShowLinkforInprotechWeb === true : false);
        });

        this.searchService.timeSummary$
            .pipe(takeUntil(this.destroy$), distinctUntilChanged())
            .subscribe((data: TimeSummary) => {
                this.timeSummary = data;
            });

        this.initMenuActions();
        this.initGridOptions();
        this.initTimeSearchPeriods();
        this.subscribeToExportContent();
        this.bgContentId$ = new BehaviorSubject<number>(null);
        this.dwlContentId$ = new BehaviorSubject<number>(null);
        this.subscribeToContents();
        this._hasSearchBeenRun.next(false);
        this.subscribeToRowSelection();
        this._hasRowSelection.next(false);
        this.timeService.showKeepOnTopNotes();
    }

    subscribeToRowSelection = () => {
        this.searchResultsGrid.rowSelectionChanged.subscribe((event) => {
            this._hasRowSelection.next(event.rowSelection.length > 0);
            this._singleEntrySelected = event.rowSelection.length !== 1 ? null : event.rowSelection[0];
        });
        this.searchResultsGrid.getRowSelectionParams().singleRowSelected$.subscribe((status) => {
            this._hasSingleRowSelection.next(status);
        });
    };

    initMenuActions(): void {
        this.bulkActions = [{
            ...new IpxBulkActionOptions(),
            id: 'export-excel',
            icon: 'cpa-icon cpa-icon-file-excel-o',
            text: 'bulkactionsmenu.ExportAllToExcel',
            enabled$: this._hasSearchBeenRun,
            click: () => this.export(ReportExportFormat.Excel)
        }, {
            ...new IpxBulkActionOptions(),
            id: 'export-word',
            icon: 'cpa-icon cpa-icon-file-word-o',
            text: 'bulkactionsmenu.ExportAllToWord',
            enabled$: this._hasSearchBeenRun,
            click: () => this.export(ReportExportFormat.Word)
        }, {
            ...new IpxBulkActionOptions(),
            id: 'export-pdf',
            icon: 'cpa-icon cpa-icon-file-pdf-o',
            text: 'bulkactionsmenu.ExportAllToPdf',
            enabled$: this._hasSearchBeenRun,
            click: () => this.export(ReportExportFormat.PDF)
        },
        {
            ...new IpxBulkActionOptions(),
            id: 'copy',
            icon: 'cpa-icon cpa-icon-file-stack-o',
            text: 'copy',
            enabled$: this._hasSingleRowSelection.asObservable().pipe(map((result) => result && this._userPermissions.canInsert)),
            click: () => this.copyEntry()
        },
        {
            ...new IpxBulkActionOptions(),
            id: 'bulk-post',
            icon: 'cpa-icon cpa-icon-clock-o',
            text: 'accounting.time.postTime.button',
            enabled$: this._hasRowSelection.asObservable().pipe(map((result) => result && this._userPermissions.canPost)),
            click: () => this.postEntries()
        },
        {
            ...new IpxBulkActionOptions(),
            id: 'bulk-delete',
            icon: 'cpa-icon cpa-icon-trash',
            text: 'accounting.time.recording.delete',
            enabled$: this._hasRowSelection.asObservable().pipe(map((result) => result && this._userPermissions.canDelete)),
            click: () => this.deleteEntries()
        },
        {
            ...new IpxBulkActionOptions(),
            id: 'bulk-edit-narrative',
            icon: 'cpa-icon cpa-icon-pencil-square-o',
            text: 'accounting.time.query.updateNarrative',
            enabled$: this._hasRowSelection.asObservable().pipe(map((result) => result && this._userPermissions.canUpdate)),
            click: () => this.updateNarrative()
        }];
    }

    initTimeSearchPeriods(): void {
        this.periods = new Array<any>();
        this.periods.push({id: 1, description: 'accounting.time.timeSearchPeriods.dateRange'});
        this.periods.push({id: 2, description: 'accounting.time.timeSearchPeriods.thisWeek'});
        this.periods.push({id: 3, description: 'accounting.time.timeSearchPeriods.thisMonth'});
        this.periods.push({id: 4, description: 'accounting.time.timeSearchPeriods.lastWeek'});
        this.periods.push({id: 5, description: 'accounting.time.timeSearchPeriods.lastMonth'});
    }

    ngOnDestroy(): void {
        this.destroy$.next(null);
        this.destroy$.complete();
        this.searchExportService
            .removeAllContents(this.messageBroker.getConnectionId()).subscribe();
        this.messageBroker.disconnectBindings(this.bindings);
        this.dwnlContentSubscription.unsubscribe();
        this.bgContentSubscription.unsubscribe();
    }

    close(): void {
        this.stateService.go('timeRecording', {
            entryDate: this.stateService.params.entryDate,
            staff: { key: this.defaultStaffNameId, displayName: this.defaultStaffName }
        });
    }

    private _initialiseFormData(): void {
        this.formData = new TimeRecordingQueryData();
        this.formData.fromDate = this.dateHelper.addMonths(this.stateService.params.entryDate || new Date(), -1);
        this.formData.toDate = null;
        this.formData.staff = { key: this.defaultStaffNameId, displayName: this.defaultStaffName };
        this.formData.isUnposted = true;
        this.formData.isPosted = true;
        this.formData.asInstructor = false;
        this.formData.asDebtor = false;
        this.formData.selectedPeriodId = this.localSettings.keys.accounting.timeSearch.periodSelection.getLocalValue();
        this.onChangePeriod(this.localSettings.keys.accounting.timeSearch.periodSelection.getLocalValue());
    }

    togglePostedOptions(ctrl: string): void {
        if (ctrl === 'isPosted' && !this.formData.isPosted) {
            this.formData.isUnposted = true;
        } else if (ctrl === 'isUnposted' && !this.formData.isUnposted) {
            this.formData.isPosted = true;
        }
        this.cdRef.detectChanges();
    }

    onEntityChanged(event: any): void {
        if (!!event) {
            this.formData.isPosted = true;
            this.formData.isUnposted = false;
        }
    }

    onNameChanged(event: any): void {
        this.formData.asInstructor = this.formData.asDebtor = !!event;
    }

    toggleNameOptions(ctrl: string): void {
        if (ctrl === 'asDebtor' && !this.formData.asDebtor) {
            this.formData.asInstructor = true;
        } else if (ctrl === 'asInstructor' && !this.formData.asInstructor) {
            this.formData.asDebtor = true;
        }
        this.cdRef.detectChanges();
    }

    onStaffChanged(staffName: any): void {
        this.selectedStaff = staffName;
        this.timeService.getUserPermissions(staffName.key)
            .pipe(takeLast(1), takeUntil(this.destroy$))
            .subscribe(this.onPermissionsRecieved.bind(this));
    }

    onPermissionsRecieved(permissions: TimeRecordingPermissions): void {
        this.userInfoService.setUserDetails({ ...this.selectedStaff, permissions });
    }

    clear(): void {
        this._initialiseFormData();
        this.searchResultsGrid.clearFilters();
        this.searchResultsGrid.clear();
        this.timeSummary = null;
        this._hasSearchBeenRun.next(false);
        this._hasRowSelection.next(false);
        this.searchResultsGrid.clearSelection();
        this.timeService.rowSelectedInTimeSearch.next(null);
    }

    search(clearFilters = false): void {
        this.postingStaff = this.formData.staff;
        if (this.userInfoService.loggedInUserNameId === this.postingStaff.key) {
            this._userPermissions = { ...this._userPermissions, canDelete: true, canPost: true, canUpdate: true, canInsert: true };
        } else {
            this.userInfoService.userDetails$.pipe(take(1)).subscribe((userAndPermissions: UserIdAndPermissions) => {
                this._userPermissions = { ...this._userPermissions, ...userAndPermissions.permissions };
            });
        }
        if (clearFilters) {
            this.searchResultsGrid.clearFilters();
        }
        this.searchResultsGrid.search();
        this._hasSearchBeenRun.next(true);
        this._hasRowSelection.next(false);
        this._isNewSearch = true;
    }

    export(format: ReportExportFormat): void {
        const exportFormat = ReportExportFormat[format].toString();
        this.searchExportService
            .generateContentId(this.messageBroker.getConnectionId())
            .pipe(take(1))
            .subscribe((contentId: number) => {
                this.exportContentTypeMapper.push({
                    contentId,
                    reportFormat: exportFormat
                });
                const columns = this.searchResultsGrid.wrapper.leafColumns.filter((column) => {
                    return !!column.title && column.title !== '';
                });
                this.searchService.exportSearch$(this.formData, this.queryParams, exportFormat, columns.map((column: ColumnComponent) => {

                    return { name: column.field.replace(/\w\S*/g, m => m.charAt(0).toUpperCase() + m.substr(1)), title: column.title };
                }), contentId)
                    .pipe(take(1),
                        tap(() => {
                            this.notificationService
                                .success(this.translate.instant('exportSubmitMessage', {
                                    value: exportFormat
                                }));
                        }),
                        takeUntil(this.destroy$))
                    .subscribe();
            });
    }

    postEntries = (): void => {
        const postingParams = this.searchService.getSearchParams(this.formData, this.queryParams);
        const postEntryDetails: PostEntryDetails = {
            staffNameId: this.postingStaff.key,
            postingParams: { searchParams: postingParams.criteria, queryParams: postingParams.queryParams }
        };
        if (this.searchResultsGrid.getRowSelectionParams().isAllPageSelect) {
            postEntryDetails.isSelectAll = true;
            postEntryDetails.exceptEntryNumbers = _.pluck(this.searchResultsGrid.getRowSelectionParams().allDeSelectedItems, 'entryNo');
        } else {
            postEntryDetails.entryNumbers = this.searchResultsGrid.getRowSelectionParams().rowSelection;
        }
        this.openPostModal(postEntryDetails);
    };

    openPostModal = (postEntryDetails: PostEntryDetails = null): void => {
        this.postTimeDialog.showDialog(postEntryDetails, null, null)
            .pipe(take(1), takeUntil(this._hasSearchBeenRun), takeUntil(this.destroy$), takeUntil(this.destroy$))
            .subscribe((postDone: boolean) => {
                if (!!postDone) {
                    this.search();
                }
            });
    };

    deleteEntries = (): void => {
        const deleteEntryDetails = this.getSelectionDetails();

        const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('accounting.time.query.deleteConfirmation');

        notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
            .subscribe(() => {
                const deleteEntriesServiceCall = this.searchService.deleteEntries(deleteEntryDetails).pipe(take(1), shareReplay(2));

                deleteEntriesServiceCall.subscribe(() => {
                    this.notificationService.success('accounting.time.query.deleteSuccess');
                });

                deleteEntriesServiceCall.pipe(takeUntil(this._hasSearchBeenRun), takeUntil(this.destroy$)).subscribe(() => {
                    this.search();
                });
            });
    };

    updateNarrative = (): void => {
        const initialState = !!this._singleEntrySelected && !this._singleEntrySelected.isPosted ? {
            defaultNarrative: _.pick(this._singleEntrySelected, 'narrativeNo', 'narrativeText', 'narrativeTitle'),
            defaultNarrativeText: this._singleEntrySelected.narrativeText,
            caseKey: this._singleEntrySelected.caseKey,
            debtorKey: this._singleEntrySelected.nameKey
        } : {};

        this.modalRef = this.modalService.openModal(UpdateNarrativeComponent, { initialState });

        race(this.modalService.onHide$.pipe(filter((e) => e.isCancelOrEscape), map(() => false)),
            this.modalRef.content.confirmed$)
            .pipe(take(1))
            .subscribe((data: any) => {
                if (!data) {
                    return;
                }
                const selectionDetails = this.getSelectionDetails();
                this.searchService.updateNarrative(selectionDetails, data)
                    .pipe(take(1), takeUntil(this.destroy$))
                    .subscribe(() => {
                        this.notificationService.success();
                        this.search();
                    });
            });
    };

    copyEntry = (): void => {
        const entry = this._singleEntrySelected;
        iif(() => _.isNumber(entry.caseKey), this.warningChecker.performCaseWarningsCheck(entry.caseKey, new Date()),
            this.warningChecker.performNameWarningsCheck(entry.nameKey, entry.name, new Date()))
            .pipe(take(1))
            .subscribe((result: boolean) => {
                if (!!result) {
                    entry.clearOutTimeSpecifications();
                    this.copyIntoTimeRecording(entry);
                }
            });
    };

    getSelectionDetails = (): BatchSelectionDetails => {
        const isSelectAll = this.searchResultsGrid.getRowSelectionParams().isAllPageSelect;

        const details: BatchSelectionDetails = ({ staffNameId: this.postingStaff.key });

        if (isSelectAll) {
            const exceptEntryNos = _.pluck(this.searchResultsGrid.getRowSelectionParams().allDeSelectedItems, 'entryNo');
            const searchParam = this.searchService.getSearchParams(this.formData, this.queryParams);
            details.reverseSelection = new ReverseSelection(searchParam.criteria, searchParam.queryParams, exceptEntryNos);
        } else {
            details.entryNumbers = this.searchResultsGrid.getRowSelectionParams().rowSelection;
            details.reverseSelection = new ReverseSelection(new TimeSearchQuery(), null, null);
        }

        return details;
    };

    private readonly subscribeToExportContent = () => {
        this.bindings.push(this.exportContentBinding);
        this.messageBroker.subscribe(this.exportContentBinding, (contents: any) => {
            this.zone.runOutsideAngular(() => {
                this.processContents(contents);
            });
        });

        this.messageBroker.connect();
    };

    subscribeToContents = () => {
        this.dwnlContentSubscription = this.dwlContentId$
            .pipe(debounceTime(100), distinctUntilChanged())
            .subscribe((contentId: number) => {
                if (contentId) {
                    this.fileDownloadService.downloadFile('api/export/download/content/' + contentId, null);
                }
            });
        this.bgContentSubscription = this.bgContentId$
            .pipe(debounceTime(100), distinctUntilChanged())
            .subscribe((contentId: number) => {
                if (contentId) {
                    const format = _.first(_.filter(this.exportContentTypeMapper, (ect) => {
                        return ect.contentId === contentId;
                    })).reportFormat;
                    this.notificationService.success(this.translate.instant('backgroundContentMessage', {
                        value: format
                    }), null, 15000);
                }
            });
    };

    processContents = (contents: Array<any>) => {
        const downloadables = _.filter(contents, (content) => {
            return content.status === ContentStatus.readyToDownload;
        });
        if (_.any(downloadables)) {
            this.processDownloadableContents(_.pluck(downloadables, 'contentId'));
        }

        const backgroundContents = _.filter(contents, (content) => {
            return content.status === ContentStatus.processedInBackground;
        });
        if (_.any(backgroundContents)) {
            this.processBackgroundContents(_.pluck(backgroundContents, 'contentId'));
        }
    };

    processDownloadableContents = (contentIds: Array<number>) => {
        _.each(contentIds, (contentId: number) => {
            this.dwlContentId$.next(contentId);
        });
    };

    processBackgroundContents = (contentIds: Array<number>) => {
        _.each(contentIds, (contentId: number) => {
            this.bgContentId$.next(contentId);
        });
    };

    initGridOptions(): void {
        const pageSizeSetting = this.localSettings.keys.accounting.timeSearch.pageSize;
        this.searchGridOptions = {
            columnPicker: true,
            filterable: true,
            navigable: true,
            sortable: true,
            autobind: false,
            reorderable: true,
            selectable: {
                mode: 'multiple'
            },
            pageable: {
                pageSizeSetting,
                pageSizes: [10, 20, 50, 100]
            },
            read$: (queryParams: GridQueryParameters) => {
                this.queryParams = queryParams;

                return this.searchService.runSearch$(this.formData, queryParams);
            },
            filterMetaData$: (column: GridColumnDefinition) => {
                return this.searchService.runFilterMetaSearch$(column.field);
            },
            columns: [{
                title: '',
                field: 'isPostedOrIncomplete',
                template: true,
                width: 20,
                sortable: false,
                fixed: true,
                includeInChooser: false
            }, {
                title: 'accounting.time.fields.date',
                field: 'entryDate',
                width: 100,
                filter: true,
                template: true
            }, {
                title: 'accounting.time.fields.case',
                field: 'caseReference',
                width: 120,
                template: true,
                filter: true
            }, {
                title: 'accounting.time.fields.name',
                field: 'name',
                width: 180,
                template: true,
                filter: true
            }, {
                title: 'accounting.time.fields.activity',
                field: 'activity',
                width: 180,
                filter: true
            }, {
                title: 'accounting.time.fields.time',
                field: 'totalDuration',
                width: 40,
                template: true
            }, {
                title: 'accounting.time.fields.units',
                field: 'totalUnits',
                template: true,
                headerClass: 'right-aligned',
                hidden: true,
                width: 20
            }, {
                title: 'accounting.time.fields.chargeOutRate',
                field: 'chargeOutRate',
                template: true,
                headerClass: 'right-aligned',
                hidden: true,
                width: 40
            }, {
                title: 'accounting.time.fields.localValue',
                field: 'localValue',
                width: 40,
                template: true,
                headerClass: 'right-aligned'
            }, {
                title: 'accounting.time.fields.localDiscount',
                field: 'localDiscount',
                width: 40,
                template: true,
                headerClass: 'right-aligned'
            }, {
                title: 'accounting.time.fields.foreignValue',
                field: 'foreignValue',
                width: 40,
                template: true,
                headerClass: 'right-aligned'
            }, {
                title: 'accounting.time.fields.foreignDiscount',
                field: 'foreignDiscount',
                width: 40,
                template: true,
                headerClass: 'right-aligned',
                hidden: true
            }, {
                title: 'accounting.time.fields.narrativeText',
                field: 'narrativeText',
                width: 300,
                template: true
            }, {
                title: 'accounting.time.fields.notes',
                field: 'notes',
                width: 300,
                template: true,
                hidden: true
            }],
            sort: [{
                field: 'entryDate',
                dir: 'desc'
            }],
            columnSelection: {
                localSetting: this.getColumnSelectionLocalSetting()
            },
            customRowClass: (context) => {
                let returnValue = '';
                const dataItem = new TimeEntryEx(context.dataItem);
                if (dataItem.isPosted) {
                    returnValue += ' posted';
                }

                return returnValue;
            },
            bulkActions: this.bulkActions,
            selectedRecords: {
                rows: {
                    rowKeyField: 'entryNo',
                    selectedKeys: []
                }
            },
            onDataBound: () => {
                if (this._isNewSearch) {
                    this.searchResultsGrid.clearSelection();
                    this._isNewSearch = false;
                }
            }
        };
    }

    dataItemClicked = (event: any): any => {
        const caseKey = event && event.caseKey != null ? event.caseKey : null;
        const nameKey = event && event.nameKey != null ? event.nameKey : null;

        !caseKey && nameKey ? this.timeService.rowSelectedInTimeSearch.next({ id: nameKey, type: KotViewForEnum.Name })
            : this.timeService.rowSelectedInTimeSearch.next({ id: caseKey, type: KotViewForEnum.Case });

    };

    encodeLinkData = (data: any) =>
        'api/search/redirect?linkData=' +
        encodeURIComponent(JSON.stringify({ nameKey: data }));

    getColumnSelectionLocalSetting = () => {
        return this.localSettings.keys.accounting.timeSearch.columnsSelection;
    };
    navigateToTimeRecording = (entryDate: Date, entryNo: number): void => {
        this.stateService.go('timeRecording', {
            entryDate,
            staff: { key: this.formData.staff.key, displayName: this.formData.staff.displayName },
            entryNo
        });
    };
    copyIntoTimeRecording = (entry: TimeEntryEx): void => {
        this.stateService.go('timeRecording', {
            entryDate: this.stateService.params.entryDate || new Date(),
            staff: { key: this.defaultStaffNameId, displayName: this.defaultStaffName },
            copyFromEntry: entry
        });
    };

    onChangePeriod = (event: any): void => {
        const currentDate = new Date();
        if (event === 2) {
            const week = TimeRecordingHelper.currentWeek(currentDate);
            this.formData.fromDate = new Date(_.first(week));
            this.formData.toDate = new Date(_.last(week));
        }
        if (event === 4) {
            const week = TimeRecordingHelper.lastWeek(currentDate);
            this.formData.fromDate = new Date(_.first(week));
            this.formData.toDate = new Date(_.last(week));
        }
        if (event === 3) {
            const month = TimeRecordingHelper.currentMonth();
            this.formData.fromDate = new Date(_.first(month));
            this.formData.toDate = new Date(_.last(month));
        }
        if (event === 5) {
            const month = TimeRecordingHelper.lastMonth();
            this.formData.fromDate = new Date(_.first(month));
            this.formData.toDate = new Date(_.last(month));
        }
        this.localSettings.keys.accounting.timeSearch.periodSelection.setLocal(event);
    };

}

class TimeSearchParameters {
    entities: Array<any>;
}

class TimeSummary {
    totalUnits?: number;
    totalValue?: number;
    totalDiscount?: number;
    totalHours?: number;
}
