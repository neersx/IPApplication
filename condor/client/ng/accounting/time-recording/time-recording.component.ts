import { DatePipe } from '@angular/common';
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, NgZone, OnDestroy, OnInit, Output, Self, TemplateRef, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/core';
import { AccountingService } from 'accounting/financials/accounting.service';
import { TimerSeed } from 'accounting/time-recording-widget/time-recording-timer-model';
import { WarningCheckerService } from 'accounting/warnings/warning-checker.service';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import * as angular from 'angular';
import { AttachmentModalService } from 'common/attachments/attachment-modal.service';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { KotViewForEnum } from 'rightbarnav/keep-on-top-notes-view.service';
import { QuickNavModel, RightBarNavService } from 'rightbarnav/rightbarnav.service';
import { TimeRecordingPreferencesComponent } from 'rightbarnav/time-recording-preferences/time-recording-preferences.component';
import { iif, Observable, of, race, ReplaySubject, Subject } from 'rxjs';
import { concatMap, delay, distinctUntilChanged, filter, finalize, map, skip, switchMap, take, takeUntil, takeWhile, tap } from 'rxjs/operators';
import { CaseWebLinksTaskProvider } from 'search/common/case-web-links-task-provider';
import { IpxClockComponent } from 'shared/component/forms/ipx-clock/ipx-clock.component';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { IpxTextFieldComponent } from 'shared/component/forms/ipx-text-field/ipx-text-field.component';
import { GridFocusDirective } from 'shared/component/grid/ipx-grid-focus.directive';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { EnterPressedEvent } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { MouseKeyboardEventHandlerDirective } from 'shared/component/grid/ipx-mouse-keyboard-event-handler.directive';
import { HideEvent, IpxModalService } from 'shared/component/modal/modal.service';
import { IpxInfoComponent } from 'shared/component/notification/ipx-info/ipx-info.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxTypeaheadComponent } from 'shared/component/typeahead/ipx-typeahead';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { LocaleDatePipe } from 'shared/pipes/locale-date.pipe';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as _ from 'underscore';
import { TimeMessagingService } from '../time-recording-widget/message.service';
import { AdjustValueComponent } from './adjust-value/adjust-value.component';
import { CaseBillNarrativeComponent } from './case-bill-narrative/case-bill-narrative.component';
import { ChangeEntryDateComponent } from './change-entry-date/change-entry-date.component';
import { CopyTimeEntryComponent } from './copy-time-entry/copy-time-entry.component';
import { DuplicateEntryComponent } from './duplicate-entry/duplicate-entry.component';
import { DuplicateEntryService } from './duplicate-entry/duplicate-entry.service';
import { ContinuedTimeHelper } from './helpers/continued-time-helper';
import { DebtorSplitsComponent } from './multi-debtor/debtor-splits.component';
import { PostTimeDialogService } from './post-time/post-time-dialog.service';
import { TimeSettingsService } from './settings/time-settings.service';
import { UserInfoService } from './settings/user-info.service';
import { TimeGapsComponent } from './time-gaps/time-gaps.component';
import { EnquiryViewData, TimeEntry, TimeEntryEx, TimeRecordingHeader, TimeRecordingPermissions, UserIdAndPermissions, WipStatusEnum } from './time-recording-model';
import * as timesheet from './time-recording.namespace';
import { TimesheetFormsService } from './timesheet-forms.service';
@Component({
    selector: 'time-recording',
    templateUrl: './time-recording.component.html',
    styleUrls: ['./time-recording.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [PostTimeDialogService]
})
export class TimeRecordingComponent implements OnInit, OnDestroy, AfterViewInit {
    @ViewChild('caseRef', { static: false }) _caseRef: IpxTypeaheadComponent;
    @ViewChild('nameRef', { static: false }) _nameRef: IpxTypeaheadComponent;
    @ViewChild('narrativeTitle', { static: false }) _narrativeTitleRef: IpxTypeaheadComponent;
    @ViewChild('narrativeText', { static: false, read: IpxTextFieldComponent }) _narrativeTextRef: IpxTextFieldComponent;
    @ViewChild('notes', { static: false, read: IpxTextFieldComponent }) _notesRef: IpxTextFieldComponent;
    @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;
    @ViewChild('ipxKendoGridRef', { static: true }) _grid: IpxKendoGridComponent;
    @ViewChild('ipxKendoGridRef', { static: true, read: GridFocusDirective }) _gridFocus: GridFocusDirective;
    @ViewChild('ipxKendoGridRef', { static: true, read: MouseKeyboardEventHandlerDirective }) _gridKeyboardHandler: MouseKeyboardEventHandlerDirective;
    @ViewChild('timerClock', { static: false }) _timer: IpxClockComponent;
    @Output() readonly onRowSelect = new EventEmitter();
    showSummary: Boolean = true;
    gridOptions: IpxGridOptions;
    currentDate: Date;
    isTodaySelected: boolean;
    selectedDate: string;
    selectedCaseKey: String;
    canViewCaseAttachments: boolean;
    canPostForAllStaff: boolean;
    timeRecordingSettings: timesheet.TimeRecordingSettings;
    localCurrencyCode: string;
    viewData: EnquiryViewData;
    onDateChanged: (event: any) => void;
    rowSelected = new Subject();
    formGroup: FormGroup;
    activityExtendQuery: any;
    caseExtendQuery: any;
    narrativeExtendQuery: any;
    modalRef: BsModalRef;
    updatedEntryNo: number;
    shortcut: string;
    externalScope: any;
    defaultedNarrativeText: any;
    incompleteEntryText: string;
    entryInEdit?: number;
    originalDetails: any;
    hasAddedRow: boolean;
    isSaveCalled = false;
    valueTimeOnEntry = false;
    taskItems: any;
    taskItemsForUnpostedEntry: any;
    taskItemsForPostedEntry: any;
    newChildEntry?: any;
    headerInfo: TimeRecordingHeader;
    staffNameId?: number = null;
    displayName?: string;
    actions = ['CONTINUE_TIME', 'CONTINUE_TIMER', 'EDIT_TIME', 'CHANGE_ENTRY_DATE', 'POST_TIME', 'DELETE_TIME', 'ADJUST_VALUES', 'DUPLICATE_ENTRY'];
    allowedActions: Array<string> = [...this.actions];
    hasPendingSave: boolean;
    enterEventSub: any;
    destroy: ReplaySubject<any> = new ReplaySubject<any>(1);
    cellEnterPressed?: number = null;
    navigateToEntry?: number = null;
    navigateToStaff?: { key: number, displayName: string } = null;
    bindings: Array<string>;
    initCaseKey?: number;
    initCaseRef?: string;
    initEntryInEdit?: number;
    copyFromEntry?: TimeEntryEx;
    isStaff: boolean;
    displayOverlaps: boolean;
    dataType: any = dataTypeEnum;
    canMaintainCaseBillNarrative: boolean;

    constructor(
        private readonly timeService: timesheet.TimeRecordingService,
        readonly timeCalcService: timesheet.TimeCalculationService,
        private readonly dateHelperService: DateHelper,
        private readonly accountingService: AccountingService,
        readonly localSettings: timesheet.LocalSettings,
        private readonly rootScopeService: RootScopeService,
        private readonly notificationService: NotificationService,
        private readonly warningChecker: WarningCheckerService,
        private readonly modalService: IpxModalService,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly rightBarNavService: RightBarNavService,
        private readonly timeGridHelper: timesheet.TimeGridHelper,
        private readonly cdRef: ChangeDetectorRef,
        @Self() private readonly postTimeDialog: PostTimeDialogService,
        readonly settingsService: TimeSettingsService,
        readonly formsService: TimesheetFormsService,
        readonly translate: TranslateService,
        readonly userInfo: UserInfoService,
        readonly datePipe: DatePipe,
        readonly localDate: LocaleDatePipe,
        private readonly stateService: StateService,
        private readonly duplicateEntryService: DuplicateEntryService,
        private readonly continuedTimeHelper: ContinuedTimeHelper,
        private readonly zone: NgZone,
        private readonly messagingService: TimeMessagingService,
        private readonly shortcutService: IpxShortcutsService,
        private readonly caseWebLinksProvider: CaseWebLinksTaskProvider,
        private readonly attachmentModalService: AttachmentModalService
    ) {
        if (this.stateService.params.caseId) {
            this.stateService.go('timeRecordingForCase', { caseKey: this.stateService.params.caseId });
        }
        this.initCaseKey = this.stateService.params.caseKey;
        this.currentDate = this.stateService.params.entryDate || new Date();
        this.selectedDate = this.dateHelperService.toLocal(this.currentDate);
        const user = this.rootScopeService.rootScope.appContext.user;
        this.accountingService.canViewReceivables = user.permissions.canViewReceivables;
        this.accountingService.canViewWorkInProgress = user.permissions.canViewWorkInProgress;
        this.canMaintainCaseBillNarrative = user.permissions.canMaintainCaseBillNarrative;
        this.localCurrencyCode = user.preferences.currencyFormat.localCurrencyCode;
        this.accountingService.currencyCode = user.preferences.currencyFormat.localCurrencyCode;
        this.activityExtendQuery = this.activitiesFor.bind(this);
        this.caseExtendQuery = this.casesFor.bind(this);
        this.narrativeExtendQuery = this.narrativesFor.bind(this);
        this.externalScope = this.nameExternalScopeForCase.bind(this);
        this.navigateToEntry = this.stateService.params.entryNo;
        this.navigateToStaff = this.stateService.params.staff;
        this.setContextNavigation();
        this.copyFromEntry = this.stateService.params.copyFromEntry;
    }

    ngAfterViewInit(): void {
        this.enterEventSub = this._gridKeyboardHandler.onEnter.subscribe((d: EnterPressedEvent) => {
            if (d.rowState.isInEditMode || (!!this.entryInEdit && this.entryInEdit === d.dataItem.entryNo || d.dataItem.isPosted || d.dataItem.isContinuedParent || !this.isSavedEntry(d.dataItem.entryNo))) {
                return;
            }
            this.cellEnterPressed = d.colIndex;
            this.editTime(d.dataItem);
        });
    }

    ngOnInit(): void {
        this.settingsService.getViewData$(this.initCaseKey, !!this.navigateToStaff ? this.navigateToStaff.key : null).subscribe((response: EnquiryViewData) => {
            this.canViewCaseAttachments = response.canViewCaseAttachments;
            this.canPostForAllStaff = response.canPostForAllStaff;
            this.timeRecordingSettings = { ...response.settings };
            this.incompleteEntryText = 'accounting.time.recording.incompleteEntry';
            this.warningChecker.restrictOnWip = this.timeRecordingSettings.restrictOnWip;
            if (!!response.userInfo) {
                this.displayName = response.userInfo.displayName;
                this.staffNameId = response.userInfo.nameId;
                this.isStaff = response.userInfo.isStaff;
                this.formsService.staffNameId = this.staffNameId;
                if (!response.userInfo.canAdjustValues) {
                    this.allowedActions = _.without(this.actions, 'ADJUST_VALUES');
                }
            }
            this.initializeTaskItems();
            this.cdRef.markForCheck();
            this.viewData = response;
            if (response.defaultInfo) {
                this.initCaseKey = response.defaultInfo.caseId;
                this.initCaseRef = response.defaultInfo.caseReference;
            }
        });
        this.gridOptions = this.buildGridOptions();
        this.onDateChanged = (event: any) => {
            this.resetForm();
            this.formsService.dateChanged(event !== null);

            if (!event) {
                return;
            }
            this.selectedDate = this.dateHelperService.toLocal(event);
            this.currentDate = event;
            this.timeCalcService.selectedDate = new Date(this.currentDate);
            this.gridOptions.enableGridAdd = true;
            this._grid.collapseAll();
            this.gridOptions._closeEditMode();
            this.refreshGrid();
            this.isTodaySelected = this.dateHelperService.toLocal(new Date()) === this.dateHelperService.toLocal(this.currentDate);
            if (!!this.timeRecordingSettings) {
                this.initializeTaskItems(!this.isTodaySelected);
            }
        };
        this.showSummary = !(this.localSettings.keys.accounting.timesheet.hidePreview.getLocal);

        this.onTimesheetForNameChanged();
        this.timeService.onRecordUpdated().pipe(takeUntil(this.destroy)).subscribe(this._recordDataChange);
        this.timeService.showKeepOnTopNotes();
        this.messagingService.message$.pipe(takeUntil(this.destroy)).subscribe((message: any) => {
            if (!!message && !!message.basicDetails) {
                if (!message.hasActiveTimer && !!message.hasAutoStoppedTimer) {
                    this.refreshGrid();
                }
                const timerEntryNo = message.basicDetails.entryNo;
                if (this.entryInEdit === timerEntryNo && !message.hasActiveTimer) {
                    this.resetForm();
                }
                this.timeService._applyNewData(timerEntryNo, { ...message.basicDetails, isTimer: message.hasActiveTimer });
                this.cdRef.detectChanges();
            }
        });
        this.handleShortcuts();
    }

    today = () => {
        const today = new Date();
        if (this.dateHelperService.toLocal(today) !== this.dateHelperService.toLocal(this.currentDate)) {
            this.currentDate = today;
        }
    };

    previous = () => {
        const previous = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth(), this.currentDate.getDate());
        previous.setDate(previous.getDate() - 1);
        this.currentDate = previous;
    };

    next = () => {
        const next = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth(), this.currentDate.getDate());
        next.setDate(next.getDate() + 1);
        this.currentDate = next;
    };

    buildGridOptions(): IpxGridOptions {
        return {
            sortable: true,
            columnPicker: true,
            filterable: true,
            selectable: {
                mode: 'single'
            },
            autobind: false,
            read$: (queryParams) => this.timeService.getTimeList({
                selectedDate: this.selectedDate,
                updatedEntryNo: this.updatedEntryNo,
                staffNameId: !!this.navigateToStaff ? this.navigateToStaff.key : this.staffNameId
            }, queryParams),
            detailTemplate: this.detailTemplate,
            columns: this.timeGridHelper.getColumns(),
            customRowClass: (context) => {
                let returnValue = '';
                const dataItem = new TimeEntryEx(context.dataItem);
                if (!!this.timeRecordingSettings && this.timeRecordingSettings.hideContinuedEntries && context.dataItem.isContinuedParent) {
                    return 'hide-row';
                }
                if (context.dataItem.isIncomplete) {
                    returnValue += ' error';
                } else if (context.dataItem.isUpdated) {
                    returnValue += ' saved';
                } else if (context.dataItem.isContinuedParent || context.dataItem.isLastChild) {
                    returnValue += ' continued';
                }

                if (context.dataItem.isContinuedGroup) {
                    returnValue += ' continued-group';
                }
                if (context.dataItem.isLastChild) {
                    returnValue += ' continued-last';
                }

                const isposted = dataItem.isContinuedParent ?
                    _.findWhere(this.timeService.timeList, { entryNo: dataItem.childEntryNo }).isPosted
                    : dataItem.isPosted;

                if (isposted) {
                    returnValue += ' posted';
                }

                if (this.isSavedEntry(dataItem.entryNo) && this.entryInEdit === dataItem.entryNo && this.formsService.hasPendingChanges) {
                    returnValue += ' edited';
                }

                return returnValue;
            },
            columnSelection: {
                localSetting: this.timeGridHelper.getColumnSelectionLocalSetting()
            },
            onDataBound: (boundData: any) => {
                this.timeService.rowSelectedForKot.next(null);
                if (!!boundData && boundData.length > 0) {
                    if (this.updatedEntryNo) {
                        this.updatedEntryNo = null;
                        const idx = boundData.findIndex(d => d.isUpdated === true);
                        this._setFocusOnRow(idx);
                    } else if (this.navigateToEntry) {
                        const idx = boundData.findIndex(d => d.entryNo === this.navigateToEntry);
                        this._setFocusOnRow(idx >= 0 ? idx : 0);
                    } else {
                        this._setFocusOnRow(0);
                    }
                    if (this.isSaveCalled && this.timeRecordingSettings.addEntryOnSave) {
                        this.timeGridHelper.kendoAddOnSave(this.gridOptions);
                        this.isSaveCalled = false;
                    }
                } else {
                    this.selectedCaseKey = null;
                }
                this.headerInfo = { viewTotals: this.timeService.getViewTotals() };
                this.gridOptions.enableGridAdd = true;
                this.entryInEdit = null;
                this.hasAddedRow = false;
                this.newChildEntry = null;
                this.formsService.isContinuedEntryMode = false;
                if (!!this.initCaseKey) {
                    this._grid.addRow();
                    setTimeout(() => {
                        if (!!this.initCaseKey) {
                            this.formsService.caseReference.patchValue({ key: this.initCaseKey, code: this.initCaseRef }, { emitEvent: true });
                            this._caseRef.search(this.initCaseRef, null);
                            this.initCaseKey = null;
                        }
                    }, 500);
                }
                if (!!this.copyFromEntry) {
                    this._grid.addRow();
                    this.gridOptions.formGroup = this.createFormGroup(this.copyFromEntry);
                    this.copyFromEntry = null;
                }
                if (_.isNumber(this.initEntryInEdit)) {
                    const entry = this.timeService.getTimeEntryFromList(this.initEntryInEdit);
                    this.editTime(entry);
                    this.initEntryInEdit = null;
                }
                this.navigateToStaff = null;
            },
            canAdd: true,
            itemName: 'accounting.time.recording.timeEntry',
            createFormGroup: this.createFormGroup.bind(this),
            itemTemplate: new timesheet.TimeEntryEx(),
            enableGridAdd: true,
            persistSelection: false,
            reorderable: true,
            navigable: true,
            showContextMenu: true,
            showExpandCollapse: true,
            pageable: false
        };
    }

    createFormGroup(event: TimeEntryEx): FormGroup {
        this.gridOptions.reorderable = false;
        this.gridOptions.formGroup = this.formsService.createFormGroup(event);

        if (this.cellEnterPressed !== -1) {
            this._gridFocus.focusEditableField(this.cellEnterPressed);
            this.cellEnterPressed = null;
        }

        return this.gridOptions.formGroup;
    }

    getStartTime(): Date {
        return this.timeCalcService.getStartTime(this.currentDate);
    }

    dataItemClicked = (event: TimeEntryEx): any => {
        this.timeService.timeList.map((item: any) => {
            item.isContinuedGroup = false;
        });
        const selected = event;
        this.selectedCaseKey = selected && selected.caseKey != null ? selected.caseKey.toString() : null;
        const nameKey = event && event.nameKey != null ? event.nameKey : null;
        if (event.rowId !== null) {
            if (!this.selectedCaseKey && nameKey) {
                this.timeService.rowSelectedForKot.next({ id: nameKey.toString(), type: KotViewForEnum.Name });

            } else {
                this.timeService.rowSelectedForKot.next({ id: this.selectedCaseKey, type: KotViewForEnum.Case });
            }
        }
        // raise an event so the child component can know.
        if (this.isSavedEntry(event.entryNo)) {
            this.timeService.rowSelected.next(+this.selectedCaseKey);
        } else {
            const newCase = this.formsService.getSelectedCaseRef();
            if (newCase) {
                this.timeService.rowSelected.next(newCase.key);
            }
        }

        if (event.isLastChild || event.isContinuedParent) {
            this._markEntriesInChain(event.entryNo, event.childEntryNo);
        }
    };

    _markEntriesInChain = (entryNo: number, childEntryNo?: number): void => {
        if (!this.isSavedEntry(entryNo) && !this.isSavedEntry(childEntryNo)) {
            return;
        }
        const entryNoToGroup = !this.isSavedEntry(childEntryNo) ? entryNo : childEntryNo;
        _.chain(this.timeService.timeList)
            .filter((d: TimeEntryEx) => { return d.entryNo === entryNoToGroup || d.childEntryNo === entryNoToGroup; })
            .map((entry) => {
                entry.isContinuedGroup = true;
            });
    };

    trackContinuationBy = (index: number, item: any): number => {
        return item.entryNo;
    };

    getContinuedList = (dataItem: any): Array<any> => {
        if (!!dataItem.continuedChain) {

            return dataItem.continuedChain;
        }
        const chain = new Array<any>({ entryNo: dataItem.entryNo, start: dataItem.start, finish: dataItem.finish, elapsedTimeInSeconds: dataItem.elapsedTimeInSeconds });
        this._getParentEntry(dataItem, chain);
        dataItem.continuedChain = chain;

        return chain;
    };

    _getParentEntry = (dataItem: any, list: Array<any>): void => {
        const parentEntry = _.find(this.timeService.timeList, (item: any) => {
            return !!item.entryNo && item.entryNo === dataItem.parentEntryNo;
        });
        if (!!parentEntry) {
            list.push({ entryNo: parentEntry.entryNo, start: parentEntry.start, finish: parentEntry.finish, elapsedTimeInSeconds: this.timeCalcService.getElapsedSeconds(new Date(parentEntry.start), new Date(parentEntry.finish)) });
            this._getParentEntry(parentEntry, list);
        }
    };

    setStoreOnToggle(event: Event): void {
        this.localSettings.keys.accounting.timesheet.hidePreview.setLocal(!event);
    }

    onSave = (dataEntry: any): void => {
        if (this.hasAddedRow) {
            this.saveTime();

            return;
        }
        this.updateTime(dataEntry);
    };

    saveTime = (): void => {
        this.formsService.defaultFinishTime();
        if (this.hasPendingSave) {

            return;
        }
        if (!this.formsService.isFormValid) {
            return;
        }
        this.hasPendingSave = true;
        this.isSaveCalled = true;
        this.timeService.saveTimeEntry(this.formsService.getDataToSave())
            .pipe(takeUntil(this.destroy), finalize(() => { this.hasPendingSave = false; }))
            .subscribe((res: any) => {
                if (!!res && this.timeService.timeList) {
                    this.updatedEntryNo = res.response.entryNo;
                }
                this.hasPendingSave = false;
                this.notificationService.success();
                this.refreshGrid();
                this.resetForm();
            });
    };

    changeEntryDate = (dataItem: TimeEntryEx): void => {
        this.canEditPostedTime(dataItem.isPosted, dataItem)
            .pipe(take(1), takeUntil(this.destroy), filter((res) => !!res))
            .subscribe(() => {
                const initialState = {
                    item: dataItem,
                    initialDate: this.currentDate,
                    isContinued: dataItem.isLastChild,
                    openPeriods: dataItem.isPosted ? this.timeService.getOpenPeriods().pipe(take(1)) : of({})
                };
                this.modalRef = this.modalService.openModal(ChangeEntryDateComponent, {
                    animated: false,
                    ignoreBackdropClick: true,
                    initialState
                });
                this.modalRef.content.saveClicked.subscribe((newDate: Date) => {
                    if (newDate) {
                        this.timeService
                            .updateDate(newDate, initialState.item)
                            .subscribe((res) => {
                                if (!!res.error) {
                                    const alert = this.translate.instant(`accounting.errors.${res.error.alertID}`);
                                    this.ipxNotificationService.openAlertModal(null, alert);

                                    return;
                                }

                                this.notificationService.success();
                                this.refreshGrid();
                            });
                    }
                });
            });
    };

    deleteTime = (dataItem: TimeEntryEx): void => {
        this.canEditPostedTime(dataItem.isPosted && !dataItem.isContinuedParent, dataItem, false)
            .pipe(take(1), takeUntil(this.destroy))
            .subscribe((res) => {
                if (!res) {
                    return;
                }

                dataItem.entryDate = this.timeCalcService.toLocalDate(this.currentDate, true);
                const isContinued = !!dataItem.parentEntryNo || !!dataItem.childEntryNo;
                const notificationRef = dataItem.isPosted
                    ? this.ipxNotificationService.openDeleteConfirmModal(isContinued ? 'accounting.time.recording.validationMsgs.deletePostedContinuedEntry' : 'accounting.time.recording.validationMsgs.deletePostedEntry', null, isContinued, isContinued ? 'accounting.time.recording.deletePostedContinuedChain' : null)
                    : this.ipxNotificationService.openDeleteConfirmModal(isContinued ? 'accounting.time.recording.validationMsgs.deleteContinuedEntry' : 'accounting.time.recording.deleteTime', null, isContinued, isContinued ? 'accounting.time.recording.deleteContinuedChain' : null);

                notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
                    .subscribe((option) => {
                        if (option === 'confirmApply') {
                            this.timeService.deleteContinuedChain(dataItem).pipe(takeUntil(this.destroy))
                                .subscribe((response: any) => this.handleDeleteResponse(response));
                        } else {
                            this.timeService.deleteTimeEntry(dataItem).pipe(takeUntil(this.destroy))
                                .subscribe((response: any) => this.handleDeleteResponse(response));
                        }
                    });
                notificationRef.content.cancelled$.pipe(takeWhile(() => !!notificationRef))
                    .subscribe(() => { this._gridFocus.focusFirstEditableField(); });
            });
    };

    private readonly handleDeleteResponse = (details: any): void => {
        if (!!details.error) {
            const alert = this.translate.instant(`accounting.errors.${details.error.alertID}`);
            this.ipxNotificationService.openAlertModal(null, alert);

            return;
        }
        this.resetForm();
        this.refreshGrid();
    };

    resetForm = (closeRow = true): void => {
        this.gridOptions.reorderable = true;
        this.gridOptions.enableGridAdd = true;
        this.entryInEdit = null;
        this._grid.closeRow(closeRow, true);
        this.formsService.resetForm();
        this.gridOptions.formGroup = undefined;
        this.cdRef.markForCheck();
    };

    editTime = (event: any, setFocus?: Function): void => {
        this.checkOnCurrentEntryInForm().pipe(take(1), concatMap(() => this.canEditPostedTime(event.isPosted, event, true)), take(1), takeUntil(this.destroy))
            .subscribe((canEdit: boolean) => {
                if (!canEdit) {
                    return;
                }
                this.newChildEntry = null;
                this.entryInEdit = event.entryNo;
                this.defaultedNarrativeText = event.narrativeText;
                this.gridOptions.editRow(this.timeService.getRowIdFor(event.entryNo), event);

                // to prevent from adding a row when in edit mode
                this.gridOptions.enableGridAdd = false;

                if (!!setFocus) {
                    setFocus();
                }
            });
    };

    cancelEdit = (event): void => {
        if (this.formsService.hasPendingChanges) {
            this.modalRef = this.ipxNotificationService.openDiscardModal();

            this.modalRef.content.confirmed$.pipe(takeWhile(() => !!this.modalRef))
                .subscribe(() => {
                    this.resetToPreviousValues(event);
                    this.gridOptions.enableGridAdd = true;
                });

            this.modalRef.content.cancelled$.pipe(takeWhile(() => !!this.modalRef))
                .subscribe(() => { this._gridFocus.focusFirstEditableField(); });

            this.ipxNotificationService.onHide$.pipe(takeWhile(() => !!this.modalRef))
                .subscribe(() => { this._gridFocus.focusFirstEditableField(); });

            return;
        }
        this.resetForm(false);
        this.gridOptions.enableGridAdd = true;
    };

    cancelContinued = (): void => {
        if (this.hasAddedRow) {
            // close the edit for the added row and delete it from the grid
            this._removeNewlyAddedRow();
            this.timeService.setLastChildStatus(this.newChildEntry.parentEntryNo, true);
            this.newChildEntry = null;
        }
    };

    cancelAdd = (): void => {
        this._removeNewlyAddedRow();
        if (this.timeService.timeList.length === 0) {
            this._grid.gridMessage = 'noResultsFound';
        }
    };

    private readonly _removeNewlyAddedRow = (): void => {
        this.resetForm();
        this.gridOptions.removeRow(0);
        this.hasAddedRow = false;
        this.gridOptions.enableGridAdd = true;
        this._grid.navigateByIndex(0);
    };

    resetToPreviousValues(event: TimeEntryEx): void {
        this.formsService.resetOriginalValues(event);
        this.resetForm(false);
        this.gridOptions.enableGridAdd = true;
    }

    updateTime = (event: TimeEntryEx = null): void => {
        this.formsService.defaultFinishTime();
        if (!this.formsService.isFormValid) {
            return;
        }
        this.timeService.updateTimeEntry({ ...this.formsService.getDataToSave(), entryNo: event ? event.entryNo : this.entryInEdit, isPosted: event.isPosted })
            .pipe(takeUntil(this.destroy))
            .subscribe((res: any) => {
                if (!!res.error) {
                    const alert = this.translate.instant(`accounting.errors.${!!res.error.alertID ? res.error.alertID : res.error}`);
                    this.ipxNotificationService.openAlertModal(null, alert);

                    return;
                }
                if (!!res && this.timeService.timeList) {
                    this.updatedEntryNo = res.response.entryNo;
                }
                this.notificationService.success();
                this.resetForm(false);
                this.refreshGrid();
            });
    };

    activitiesFor(query: any): void {
        const selectedCase = this.formsService.getSelectedCaseRef();
        const extended = _.extend({}, query, {
            caseId: selectedCase ? selectedCase.key : null
        });

        return extended;
    }

    casesFor(query: any): void {
        const selectedName = this.formsService.getSelectedName();
        const extended = _.extend({}, query, {
            nameKey: selectedName ? selectedName.key : null
        });

        return extended;
    }

    narrativesFor(query: any): void {
        const selectedName = this.formsService.getSelectedName();
        const selectedCase = this.formsService.getSelectedCaseRef();
        const extended = _.extend({}, query, {
            debtorKey: selectedName ? selectedName.key : null,
            caseKey: selectedCase ? selectedCase.key : null
        });

        return extended;
    }

    onRowAdded(): void {
        this.hasAddedRow = true;
        this._grid.navigateByIndex(0);
        this._grid.wrapper.expandRow(0);
        this.timeService.rowSelected.next(null);
        if (!this.localSettings.keys.accounting.timesheet.hideFutureYearWarning.getSession) {
            if (this.currentDate == null || (new Date()).getFullYear() !== this.currentDate.getFullYear()) {
                this.showDifferentYearWarning();
            }
        }
    }

    showDifferentYearWarning(): void {
        const initialState = {
            title: 'Warning',
            showCheckBox: true,
            chkBoxLabel: 'accounting.time.recording.doNotDisplayChkBoxLabel',
            info: 'accounting.time.recording.validationMsgs.differentYearWarning'
        };
        this.modalRef = this.modalService.openModal(IpxInfoComponent, { animated: false, ignoreBackdropClick: false, initialState });
        this.modalRef.content.okClicked.pipe(takeWhile(() => !!this.modalRef))
            .subscribe((hideDialog: boolean) => {
                if (hideDialog) {
                    this.localSettings.keys.accounting.timesheet.hideFutureYearWarning.setSession(true);
                }
            });
    }

    // this is there besides the formgroup validators, because save & currDate isnt a part of the form. Hence couldnt have done as part of regular form validator
    componentInvalid(): boolean {
        return this.currentDate === null;
    }

    onCaseChanged(event: any, isPostedEntry = false): void {
        if (!!event && event.key) {
            if (!!event.instructorName) {
                this.formsService.name.setValue({ key: event.instructorNameId, displayName: event.instructorName }, { emitEvent: false });
            }
            const caseKey = event.key;
            of(caseKey).pipe(
                distinctUntilChanged(),
                switchMap((newCaseKey) => {
                    return this.warningChecker.performCaseWarningsCheck(newCaseKey, this.currentDate);
                })
            ).subscribe((result: boolean) => this._handleCaseWarningsResult(result, caseKey));
        } else if (!event && !isPostedEntry) { // because, clearing the case gives emtpy string and not null obj.
            this.formsService.name.setValue(null, { emitEvent: false });
            this.rightBarNavService.registerKot(null);
        }

        this.formsService.evaluateTime();
    }

    onNameChanged(event: any): void {
        this.formsService.caseReference.setValue(null, { emitEvent: false });
        this.rightBarNavService.registerKot(null);
        if (!!event && event.key) {
            this.warningChecker.performNameWarningsCheck(event.key, event.displayName, this.currentDate)
                .pipe(take(1), takeUntil(this.destroy))
                .subscribe((result: boolean) => this._handleNameWarningResult(result, event.key));
        }
    }

    onTimesheetForNameChanged(): void {
        this.userInfo.userDetails$
            .pipe(skip(2), takeUntil(this.destroy))
            .subscribe((data: UserIdAndPermissions) => {
                this.staffNameId = data.staffId;
                this.displayName = data.displayName;
                this.formsService.staffNameId = this.staffNameId;
                if (_.isNumber(this.staffNameId) && !!data.permissions && data.permissions.canRead) {
                    this.refreshGrid();
                    this.evaluatePermissions(data.permissions);
                } else {
                    this._grid.clear();
                    this.evaluatePermissions();
                }
                this.cdRef.markForCheck();
            });
    }

    evaluatePermissions(permissions: TimeRecordingPermissions = null): void {
        if (!!permissions) {
            this.gridOptions.canAdd = permissions.canInsert;
            this.gridOptions.enableGridAdd = permissions.canInsert;
            const interim = {
                CONTINUE_TIME: permissions.canInsert,
                CONTINUE_TIMER: permissions.canAddTimer,
                EDIT_TIME: permissions.canUpdate,
                CHANGE_ENTRY_DATE: permissions.canUpdate,
                POST_TIME: permissions.canPost,
                DELETE_TIME: permissions.canDelete,
                ADJUST_VALUES: permissions.canAdjustValue,
                DUPLICATE_ENTRY: permissions.canInsert
            };
            this.allowedActions = _.chain(interim)
                .pick((value) => { return !!value; })
                .keys()
                .value() as unknown as Array<string>;
        } else {
            this.allowedActions = [];
            this.gridOptions.canAdd = false;
            this.gridOptions.enableGridAdd = false;
        }
        this.initializeTaskItems();
    }
    initializeTaskItems = (noTimers?: boolean): void => {
        this.initializeTaskItemsForUnpostedEntry(noTimers);
        this.initializeTaskItemsForPostedEntry();
    };

    initializeTaskItemsForUnpostedEntry = (noTimers?: boolean): void => {
        const timeEntryItemActions = {
            CONTINUE_TIME: this.continueTime,
            CONTINUE_TIMER: this.continueTimer,
            EDIT_TIME: this.editTime,
            CHANGE_ENTRY_DATE: this.changeEntryDate,
            POST_TIME: this.postEntry,
            DELETE_TIME: this.deleteTime,
            ADJUST_VALUES: this.adjustValues,
            DUPLICATE_ENTRY: this.duplicateEntry,
            CASE_NARRATIVE: this.maintainCaseBillNarrative,
            CASE_WEBLINKS: this.caseWebLinksProvider.noAction,
            CASE_DOCUMENTS: this.viewCaseAttachments
        };

        const allowedActions = [...this.allowedActions];
        allowedActions.push('SEPARATOR');

        if (this.canMaintainCaseBillNarrative) {
            allowedActions.push('CASE_NARRATIVE');
        }

        if (this.canViewCaseAttachments) {
            allowedActions.push('CASE_DOCUMENTS');
        }

        allowedActions.push('CASE_WEBLINKS');

        this.taskItemsForUnpostedEntry = this.timeGridHelper.initializeTaskItems(timeEntryItemActions, (!!noTimers ? _.without(allowedActions, 'CONTINUE_TIMER') : allowedActions));
    };

    initializeTaskItemsForPostedEntry = (): void => {
        const timeEntryItemActions = {
            EDIT_TIME: this.editTime,
            DUPLICATE_ENTRY: this.duplicateEntry,
            CHANGE_ENTRY_DATE: this.changeEntryDate,
            DELETE_TIME: this.deleteTime,
            CASE_NARRATIVE: this.maintainCaseBillNarrative,
            CASE_WEBLINKS: this.caseWebLinksProvider.noAction,
            CASE_DOCUMENTS: this.viewCaseAttachments
        };

        const allowedActionsForPostedEntry = ['DUPLICATE_ENTRY'];
        if (this.settingsService.userTaskSecurity.maintainPostedTime.edit && _.contains(this.allowedActions, 'POST_TIME')) {
            allowedActionsForPostedEntry.push('EDIT_TIME');
            allowedActionsForPostedEntry.push('CHANGE_ENTRY_DATE');
            if (this.settingsService.userTaskSecurity.maintainPostedTime.delete) {
                allowedActionsForPostedEntry.push('DELETE_TIME');
            }
        }

        allowedActionsForPostedEntry.push('SEPARATOR');
        if (this.canMaintainCaseBillNarrative) {
            allowedActionsForPostedEntry.push('CASE_NARRATIVE');
        }
        if (this.canViewCaseAttachments) {
            allowedActionsForPostedEntry.push('CASE_DOCUMENTS');
        }
        allowedActionsForPostedEntry.push('CASE_WEBLINKS');

        this.taskItemsForPostedEntry = this.timeGridHelper.initializeTaskItems(timeEntryItemActions, allowedActionsForPostedEntry);
    };

    displayTaskItems(dataItem: TimeEntryEx): void {
        const isEntryInEdit = this.entryInEdit === dataItem.entryNo;
        this.taskItems = dataItem.isPosted
            ? this.timeGridHelper.reevaluateWhileDisplaying(this.taskItemsForPostedEntry, dataItem, isEntryInEdit)
            : this.timeGridHelper.reevaluateWhileDisplaying(this.taskItemsForUnpostedEntry, dataItem, isEntryInEdit);

        this.openCaseWebLinks(dataItem);
    }

    isActionAllowed(action: string): boolean {
        return _.contains(this.allowedActions, action);
    }

    nameExternalScopeForCase(): any {
        if (!!this.formsService.name.value) {
            return {
                label: 'Instructor',
                value: this.formsService.name.value ? this.formsService.name.value.displayName : null
            };
        }
    }

    isPageDirty = (): boolean => {
        return this.formsService.hasPendingChanges;
    };

    ngOnDestroy(): void {
        this.formsService.unsubscribeFormValueChanges();
        this.enterEventSub.unsubscribe();
        this.destroy.next(null);
        this.destroy.complete();
    }

    setContextNavigation = () => {
        const context = {
            timeRecordingPreferences: new QuickNavModel(TimeRecordingPreferencesComponent, {
                id: 'timeRecordingPreferences',
                title: 'accounting.time.recording.contextMenu.title',
                icon: 'cpa-icon-cog',
                tooltip: 'accounting.time.recording.contextMenu.title',
                resolve: {
                    viewData: (): Observable<any> => {
                        return of({
                            onSuccess: (settings: Array<any>): void => {
                                this.settingsService.changeSettings((settings.find(s => s.id === timesheet.TimeRecordingSettingsEnum.SHOW_SECONDS)).booleanValue, (settings.find(s => s.id === timesheet.TimeRecordingSettingsEnum.TIME_FORMAT_12HOUR)).booleanValue);

                                this.timeRecordingSettings.addEntryOnSave = (settings.find(s => s.id === timesheet.TimeRecordingSettingsEnum.ADD_ON_SAVE)).booleanValue;
                                this.timeRecordingSettings.valueTimeOnEntry = (settings.find(s => s.id === timesheet.TimeRecordingSettingsEnum.VALUE_ON_CHANGE)).booleanValue;

                                this.settingsService.continueFromCurrentTime = (settings.find(s => s.id === timesheet.TimeRecordingSettingsEnum.CONTINUE_FROM_CURR_TIME)).booleanValue;
                                this.settingsService.valueTimeOnEntry = this.timeRecordingSettings.valueTimeOnEntry;
                                this.settingsService.timePickerInterval = (settings.find(s => s.id === timesheet.TimeRecordingSettingsEnum.TIME_PICKER_INTERVAL)).integerValue;
                                this.settingsService.durationPickerInterval = (settings.find(s => s.id === timesheet.TimeRecordingSettingsEnum.DURATION_PICKER_INTERVAL)).integerValue;

                                this.refreshGridForContinuedEntries(settings);
                                this.cdRef.detectChanges();
                            }
                        });
                    }
                }
            }),
            timeGaps: new QuickNavModel(TimeGapsComponent, {
                id: 'timeGaps',
                title: 'accounting.time.gaps.contextMenu',
                icon: 'cpa-icon-clock-o-notch',
                tooltip: 'accounting.time.gaps.contextMenuTooltip',
                resolve: {
                    viewData: (): Observable<any> => {
                        return of({
                            displayName: this.displayName,
                            userNameId: this.staffNameId,
                            selectedDate: new Date(this.currentDate),
                            hasPendingChanges: this.formsService.hasPendingChanges,
                            onAddition: (firstAddedGapEntryNo: number) => {
                                this.resetForm();
                                this.refreshGrid();
                                this.initEntryInEdit = firstAddedGapEntryNo;
                            }
                        });
                    }
                }
            })
        };
        this.rightBarNavService.registercontextuals(context);
    };

    refreshGridForContinuedEntries = (settings: Array<any>): void => {
        const originalVal = !!this.timeRecordingSettings.hideContinuedEntries;
        this.timeRecordingSettings.hideContinuedEntries = (settings.find(s => s.id === timesheet.TimeRecordingSettingsEnum.HIDE_CONTINUED_ENTRIES)).booleanValue;
        if (this.timeRecordingSettings.hideContinuedEntries !== originalVal) {
            this._grid.collapseAll();
            this.refreshGrid();
        }
    };

    onMenuItemSelected = (menuEventDataItem: any): void => {
        menuEventDataItem.event.item.action(menuEventDataItem.dataItem, menuEventDataItem.event);
    };

    checkOnCurrentEntryInForm = (): Observable<any> => {
        if (this.formsService.isTimerRunning) {
            const timerInEdit = this.timeService.getTimeEntryFromList(this.entryInEdit);

            return this._updateEditableTimerData(timerInEdit);
        }

        if (this.formsService.isContinuedEntryMode) {
            this.modalRef = this.ipxNotificationService.openDiscardModal();

            this.modalRef.content.cancelled$.pipe(takeWhile(() => !!this.modalRef))
                .subscribe(() => { this._gridFocus.focusFirstEditableField(); });

            this.ipxNotificationService.onHide$.pipe(takeWhile(() => !!this.modalRef))
                .subscribe(() => { this._gridFocus.focusFirstEditableField(); });

            return this.modalRef.content.confirmed$.pipe(takeWhile(() => !!this.modalRef),
                tap(() => {
                    this.resetForm();
                    this._grid.removeRow(0);
                    this.gridOptions.enableGridAdd = true;
                    this.formsService.isContinuedEntryMode = false;
                }));
        }

        if (!this.gridOptions.enableGridAdd) {
            if (this.formsService.hasPendingChanges) {
                this.modalRef = this.ipxNotificationService.openDiscardModal();
                this.modalRef.content.cancelled$.pipe(takeWhile(() => !!this.modalRef))
                    .subscribe(() => { this._gridFocus.focusFirstEditableField(); });

                this.ipxNotificationService.onHide$.pipe(takeWhile(() => !!this.modalRef))
                    .subscribe(() => { this._gridFocus.focusFirstEditableField(); });

                return this.modalRef.content.confirmed$.pipe(takeWhile(() => !!this.modalRef), tap(() => {
                    this.resetForm(false);
                    if (this.hasAddedRow) {
                        this.gridOptions.removeRow(0);
                        this.hasAddedRow = false;
                    }
                    this.gridOptions.enableGridAdd = true;
                }));
            }

            if (this.hasAddedRow) {
                this.gridOptions.removeRow(0);
                this.hasAddedRow = false;
            }
            this.resetForm(false);
            this.gridOptions.enableGridAdd = true;
        }

        return of({});
    };

    continueTime = (dataItem: TimeEntryEx): void => {
        this.checkOnCurrentEntryInForm().pipe(takeUntil(this.destroy), take(1))
            .subscribe(() => {
                if (this.gridOptions.enableGridAdd) {
                    this._createContinuedEntry(dataItem);
                }
            });
    };

    _createContinuedEntry = (dataItem: any): void => {
        this.formsService.isContinuedEntryMode = true;
        const childEntry = { ...dataItem };
        childEntry.parentEntryNo = childEntry.entryNo;
        childEntry.entryNo = null;
        const accumulatedTimeInSeconds = childEntry.secondsCarriedForward + childEntry.elapsedTimeInSeconds;
        childEntry.timeCarriedForward = new Date(1899, 0, 1, 0, 0, accumulatedTimeInSeconds);
        childEntry.secondsCarriedForward = accumulatedTimeInSeconds;
        this.newChildEntry = childEntry;
        childEntry.start = null;
        childEntry.finish = null;
        childEntry.isIncomplete = false;
        childEntry.elapsedTimeInSeconds = 0;
        childEntry.isLastChild = true;
        this.timeService.timeList.splice(0, 0, childEntry);
        this.formsService.continue(dataItem, this.newChildEntry);
        this._grid.editRowAndDetails(0, childEntry, true);
        this.onRowAdded();
        this.gridOptions.enableGridAdd = false;
        this._markEntriesInChain(childEntry.parentEntryNo, null);
        this.timeService.setLastChildStatus(childEntry.parentEntryNo, false);
    };

    postEntry = (dataItem: any): void => {
        this.postTimeDialog.showDialog({ entryNo: dataItem.entryNo, staffNameId: this.staffNameId }, null, this.currentDate)
            .pipe(take(1), takeWhile(() => this.gridOptions.enableGridAdd), takeUntil(this.destroy))
            .subscribe((postDone: boolean) => {
                if (!!postDone) {
                    this.refreshGrid();
                    this._gridFocus.refocus();
                }
            });
    };

    openPostModal = (): void => {
        this.postTimeDialog.showDialog(null, this.canPostForAllStaff, this.currentDate).pipe(takeWhile(() => this.gridOptions.enableGridAdd), takeUntil(this.destroy))
            .subscribe((postDone: boolean) => {
                if (!!postDone) {
                    this.refreshGrid();
                    this._gridFocus.refocus();
                }
            });
    };

    adjustValues = (dataItem: TimeEntryEx): void => {
        if (!!dataItem.debtorSplits && dataItem.debtorSplits.length > 0) {
            this.ipxNotificationService.openAlertModal(null, 'accounting.time.recording.adjustValueMultiDebtorError');

            return;
        }

        const initialState = {
            item: dataItem,
            staffNameId: this.formsService.staffNameId
        };
        this.modalRef = this.modalService.openModal(AdjustValueComponent, {
            animated: false,
            ignoreBackdropClick: true, class: !!dataItem.foreignCurrency ? 'modal-lg' : '', focus: true,
            initialState
        });
        this.modalService.onHide$.pipe(filter((e: HideEvent) => e.isCancelOrEscape), takeWhile(() => !!this.modalRef))
            .subscribe(() => { this._gridFocus.refocus(); });

        this.modalRef.content.refreshGrid.pipe(takeWhile(() => !!this.modalRef))
            .subscribe((updatedEntryNo: number) => {
                if (!!updatedEntryNo) {
                    this.updatedEntryNo = updatedEntryNo;
                    this.refreshGrid();

                    return;
                }

                this._gridFocus.refocus();
            });
    };

    duplicateEntry = (dataItem: TimeEntryEx): void => {
        const initialState = {
            entryNo: dataItem.entryNo
        };

        let requestCompleted = null;
        this.modalRef = this.modalService.openModal(DuplicateEntryComponent, { focus: true, initialState });
        const resultOb = this.duplicateEntryService.requestDuplicateOb$
            .pipe(takeUntil(this.destroy), take(1),
                tap((count: number) => {
                    if (count > 0) {
                        this.notificationService.success('accounting.time.duplicateEntry.requestCompleted', { count });
                    } else {
                        this.notificationService.success('accounting.time.duplicateEntry.requestCompletedNoRecord');
                    }
                    requestCompleted = true;
                }));

        this.modalRef.content.requestRaised
            .pipe(tap(() => {
                resultOb.subscribe();
            }))
            .pipe(delay(3000), takeUntil(this.destroy), takeWhile(() => { return requestCompleted == null; }), take(1))
            .subscribe(() => {
                this.notificationService.success('accounting.time.duplicateEntry.requestRaised');
            });
    };

    maintainCaseBillNarrative = (dataItem: any): void => {
        const initialState = {
            caseKey: dataItem.caseKey
        };
        this.modalRef = this.modalService.openModal(CaseBillNarrativeComponent, {
            focus: true,
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState
        });
        this.modalRef.content.onClose$.pipe(takeWhile(() => !!this.modalRef)).subscribe(value => {
            if (value) {
                this.notificationService.success('accounting.time.caseNarrative.success');
            }
        });
    };

    openCaseWebLinks = (dataItem: any): void => {
        if (dataItem.caseKey) {
            const webLink = _.find(this.taskItems, (t: any) => {
                return t.id === 'caseWebLinks';
            });
            if (webLink && webLink.items.length === 0) {
                this.caseWebLinksProvider.subscribeCaseWebLinks(dataItem, webLink);
            }
        }
    };
    viewCaseAttachments = (dataItem: TimeEntryEx): void => {
        if (_.isNumber(dataItem.caseKey)) {
            this.attachmentModalService.displayAttachmentModal('case', dataItem.caseKey, null);
        }
    };

    getTimerDataToSave = (dataItem: TimeEntryEx): any => {
        let dataToSave = {} as any;
        if (this.entryInEdit === dataItem.entryNo) {
            dataToSave = { ...this.formsService.getDataToSave() };
        }
        dataToSave = { ...dataToSave, ..._.pick(dataItem, 'staffId', 'isTimer', 'entryNo', 'parentEntryNo') };
        dataToSave.start = this.timeService.toLocalDate(new Date(dataItem.start));

        return dataToSave;
    };

    stopTimer = (dataItem: TimeEntryEx): void => {
        let totalTimeFromTimer = null;
        totalTimeFromTimer = new Date(1899, 0, 1);
        totalTimeFromTimer.setSeconds(this._timer.time);

        const dataToSave = { ...this.getTimerDataToSave(dataItem), totalTime: this.timeService.toLocalDate(totalTimeFromTimer) };

        const action = this.formsService.isTimerRunning && !dataItem.parentEntryNo ? this.timeService.saveTimer(dataToSave, true) : this.timeService.stopTimer(dataToSave);

        action.pipe(takeUntil(this.destroy)).subscribe((entry: TimeEntryEx) => {
            if (!!entry && this.timeService.timeList) {
                this.updatedEntryNo = entry.entryNo;
                const savedTimer = this.timeService.getTimeEntryFromList(entry.entryNo);
                this._displayPopupIfStoppedTimerIsFromPrevDay(savedTimer);
            }
            this.notificationService.success();
            this.resetForm(true);
            this.refreshGrid();
        });
    };

    startTimer = (): void => {
        this.checkOnCurrentEntryInForm().pipe(takeUntil(this.destroy), take(1))
            .subscribe(() => {
                if (this.gridOptions.enableGridAdd) {
                    const timerSeed = new TimerSeed({
                        startDateTime: this.timeService.toLocalDate(this.timeCalcService.getStartTime(this.timeCalcService.selectedDate, true)),
                        staffNameId: this.staffNameId
                    });

                    this.timeService.startTimer(timerSeed).pipe(takeUntil(this.destroy))
                        .subscribe((timerInfo) => {
                            this.timeService.timeList.splice(0, 0, timerInfo.startedTimer);
                            this._grid.onDataBinding();
                            this.entryInEdit = timerInfo.startedTimer.entryNo;
                            this._grid.editRowAndDetails(0, timerInfo.startedTimer, true);
                            this.onRowAdded();
                            this.gridOptions.enableGridAdd = false;
                            setTimeout(() => {
                                this._gridFocus.focusFirstEditableField();
                            }, 10);

                            if (!!timerInfo.stoppedTimer.start) {
                                this.notificationService.success('accounting.time.recording.timerStoppedAndNewStarted', { startTime: this.datePipe.transform(timerInfo.stoppedTimer.start, this.settingsService.timeFormat) });
                            } else {
                                this.notificationService.success('accounting.time.recording.timerStarted');
                            }
                        });
                }
            });
    };

    onReset = (dataItem: TimeEntryEx, resetDetails?: boolean): void => {
        if (!!dataItem && dataItem.isTimer) {
            if (!!resetDetails) {
                this.formsService.clearTime();
            }
            dataItem.start = this.timeCalcService.getStartTime(this.timeCalcService.selectedDate, true);
            this._timer.resetTimer(dataItem.start);
            const dataToSave = this.getTimerDataToSave(dataItem);
            this.timeService.resetTimerEntry(dataToSave).subscribe();
        } else {
            this.formsService.clearTime();
        }
    };

    updateTimer = (timerInEdit: TimeEntryEx): void => {
        this._updateEditableTimerData(timerInEdit).subscribe();
    };

    private readonly _updateEditableTimerData = (timerInEdit: TimeEntryEx) => {
        return this.timeService.saveTimer(this.getTimerDataToSave(timerInEdit)).pipe(takeUntil(this.destroy),
            tap(() => {
                this.resetForm(true);
                this.hasAddedRow = false;
                this.gridOptions.enableGridAdd = true;
                this.formsService.isContinuedEntryMode = false;
            }));
    };

    private readonly _displayPopupIfStoppedTimerIsFromPrevDay = (savedTimer: TimeEntryEx): void => {
        if (this.dateHelperService.toLocal(savedTimer.finish) !== this.dateHelperService.toLocal(new Date())) {
            const info = this.translate.instant('accounting.time.recording.maxTimeTimer', { finishTime: this.datePipe.transform(savedTimer.finish, this.settingsService.timeFormat) });
            const initialState = {
                title: 'Information',
                showCheckBox: false,
                info
            };
            this.modalService.openModal(IpxInfoComponent, { animated: false, ignoreBackdropClick: false, initialState });

            return;
        }
    };

    continueTimer = (dataItem: TimeEntryEx): void => {
        this.checkOnCurrentEntryInForm().pipe(takeUntil(this.destroy), take(1))
            .subscribe(() => {
                if (this.gridOptions.enableGridAdd) {
                    const startTime = this.timeCalcService.getStartTime(this.timeCalcService.selectedDate, true);
                    const finishTimeOfParent = (dataItem.finish instanceof Date ? dataItem.finish : new Date(dataItem.finish));
                    if (!!finishTimeOfParent && !!startTime && Math.trunc(finishTimeOfParent.getTime() / 1000) > Math.trunc(startTime.getTime() / 1000)) {
                        this.notificationService.alert({ errors: [{ message: 'accounting.time.recording.continueTimerCanNotStartError' }] });

                        return;
                    }
                    const timerSeed = new TimerSeed({
                        startDateTime: this.timeService.toLocalDate(startTime),
                        staffNameId: this.staffNameId,
                        continueFromEntryNo: dataItem.entryNo
                    });
                    this.timeService.startTimer(timerSeed, true).subscribe((timerInfo) => {
                        this.timeService.timeList.splice(0, 0, new TimeEntryEx({ ...timerInfo.startedTimer, ...{ caseReference: dataItem.caseReference, name: dataItem.name, isLastChild: true } }));
                        this.cdRef.detectChanges();
                        this.onRowAdded();

                        if (!!timerInfo.stoppedTimer.start) {
                            this.notificationService.success('accounting.time.recording.timerStoppedAndNewStarted', { startTime: this.datePipe.transform(timerInfo.stoppedTimer.start, this.settingsService.timeFormat) });
                        } else {
                            this.notificationService.success('accounting.time.recording.timerStarted');
                        }
                        const parentEntry = new TimeEntryEx({
                            ...dataItem, ...{
                                elapsedTimeInSeconds: null, totalUnits: null, chargeOutRate: null, localValue: null,
                                localDiscount: null, foreignValue: null, foreignDiscount: null, isContinuedParent: true, isContinuedGroup: true, isLastChild: false
                            }
                        });
                        this.timeService.timeList.splice(this.timeService.getRowIdFor(dataItem.entryNo), 1, parentEntry);
                        this.continuedTimeHelper.updateContinuedFlag(this.timeService.timeList);
                        this.dataItemClicked(this.timeService.timeList[0]);
                    });
                }
            });
    };

    _recordDataChange = (): void => {
        this.cdRef.markForCheck();
    };

    handleClickNarrativeTitle = (dataItem: TimeEntryEx): void => this._handleDetailControlClick(dataItem, () => this._narrativeTitleRef.focus());

    handleClickNarrativeText = (dataItem: TimeEntryEx): void => this._handleDetailControlClick(dataItem, () => this._narrativeTextRef.focus());

    handleClickNotes = (dataItem: TimeEntryEx): void => this._handleDetailControlClick(dataItem, () => this._notesRef.focus());

    _handleDetailControlClick = (dataItem: TimeEntryEx, setFocus: Function): void => {
        if (timesheet.TimeGridHelper.canNotEdit(dataItem)) {

            return;
        }
        this.cellEnterPressed = -1;
        this.editTime(dataItem, () => {
            setTimeout(() => {
                setFocus();
                this.cellEnterPressed = null;
            }, 20);
        });

    };

    _setFocusOnRow = (rowIndex = 0): void => {
        setTimeout(() => {
            this._gridFocus.setFocusOnMasterRow(rowIndex, 1);
            this._grid.navigateByIndex(rowIndex);
        }, 20);
    };

    navigateToQuery = (): void => {
        this.stateService.go('timeRecordingQuery', {
            entryDate: this.currentDate
        });
    };

    isSavedEntry = (entryNo: any): boolean => {
        return _.isNumber(entryNo);
    };

    refreshGrid = (): void => {
        this._grid.search();
    };

    canEditPostedTime = (verifyEditPossible: boolean, entry: TimeEntryEx, displayConfirmation = false): Observable<boolean> => {
        if (!verifyEditPossible) {
            return of(true);
        }

        if (!!entry.debtorSplits && entry.debtorSplits.length > 0) {
            this.ipxNotificationService.openAlertModal(null, 'accounting.time.editPostedTime.multiDebtorError');

            return of(false);
        }

        return this.timeService.canPostedEntryBeEdited(entry.entryNo, entry.staffId)
            .pipe(take(1), concatMap<WipStatusEnum, Observable<boolean>>(val => {
                if (val === WipStatusEnum.Editable) {
                    if (!!displayConfirmation) {
                        const notificationRef = this.ipxNotificationService.openConfirmationModal(null, 'accounting.time.editPostedTime.editConfirmationMsg', 'Proceed', 'Cancel');

                        return notificationRef.content.confirmed$.pipe(take(1));
                    }

                    return of(true);
                }

                if (val === WipStatusEnum.Billed) {
                    this.ipxNotificationService.openAlertModal(null, 'accounting.time.editPostedTime.billedError');
                } else if (val === WipStatusEnum.Locked) {
                    this.ipxNotificationService.openAlertModal(null, 'accounting.time.editPostedTime.lockedError');
                } else if (val === WipStatusEnum.Adjusted) {
                    this.ipxNotificationService.openAlertModal(null, 'accounting.time.editPostedTime.adjustedError');
                }

                return of(false);
            }));
    };

    getAggregateDuration = (duration: Date, carriedForwardSeconds: number): number => {
        if (!!duration) {
            return DateFunctions.getSeconds(duration) + carriedForwardSeconds;
        }

        return null;
    };

    copyTimeEntry = (): void => {
        const copyTimeEntryRef = this.modalService.openModal(CopyTimeEntryComponent, {
            animated: false,
            ignoreBackdropClick: true,
            class: 'modal-xl'
        });

        const selectionMade = copyTimeEntryRef.content.selectedEntry$.pipe(tap(() => copyTimeEntryRef.hide()));
        const cancelled$ = this.modalService.onHide$.pipe(filter((r: HideEvent) => r.isCancelOrEscape), map(() => false));

        race(selectionMade, cancelled$)
            .pipe(take(1), takeUntil(this.destroy))
            .subscribe((entry: TimeEntry) => {
                if (!!entry) {
                    entry.clearOutTimeSpecifications();
                    iif(() => _.isNumber(entry.caseKey), this.warningChecker.performCaseWarningsCheck(entry.caseKey, this.currentDate),
                        this.warningChecker.performNameWarningsCheck(entry.nameKey, entry.name, this.currentDate))
                        .pipe(take(1), takeUntil(this.destroy))
                        .subscribe((result: boolean) => {
                            if (result) {
                                this._grid.addRow();
                                this.gridOptions.formGroup = this.createFormGroup(entry as TimeEntryEx);
                            }
                        });
                }
            });
    };

    private readonly _handleCaseWarningsResult = (selected: boolean, caseKey?: number): void => {
        if (selected) {
            this._gridFocus.refocus();

            this.formsService.checkIfActivityCanBeDefaulted(caseKey);
            this.formsService.evaluateTime();

            this.timeService.rowSelected.next(caseKey);
            this.timeService.rowSelectedForKot.next({ id: caseKey, type: KotViewForEnum.Case });
        } else {
            this.selectedCaseKey = null;
            this.formsService.caseReference.setValue(null, { emitEvent: false });
            this.formsService.name.setValue(null, { emitEvent: false });
            if (!!this._caseRef) {
                this._caseRef.focus();
            }
        }
    };

    private readonly _handleNameWarningResult = (selected: boolean, nameKey?: number): void => {
        if (selected) {
            this._gridFocus.refocus();

            this.formsService.defaultNarrativeFromActivity();
            this.formsService.evaluateTime();
            this.timeService.rowSelectedForKot.next({ id: nameKey, type: KotViewForEnum.Name });
        } else {
            this.formsService.name.setValue(null, { emitEvent: false });
            if (!!this._nameRef) {
                this._nameRef.focus();
            }
        }
    };

    private readonly _checkIfChanges = (checkValidity: boolean): boolean => {
        return !this.componentInvalid() && (!checkValidity || this.formsService.isFormValid) && this.formsService.hasPendingChanges;
    };

    private readonly _getEntry = (): any => {
        const entry = _.isNumber(this.entryInEdit) ? this.timeService.getTimeEntryFromList(this.entryInEdit) : null;

        return {
            entry,
            isContinued: this.formsService.isContinuedEntryMode,
            isTimer: !!entry ? entry.isTimer : false
        };
    };

    private readonly _handleSave = (): void => {
        const entryDetails = this._getEntry();
        if (!!entryDetails.isTimer) {
            this.updateTimer(entryDetails.entry);

            return;
        }

        this.onSave(entryDetails.entry);
    };

    private readonly _handleReset = (): void => {
        const entryDetails = this._getEntry();

        if (!!entryDetails.isContinued && !entryDetails.isTimer) {
            this.cancelContinued();

            return;
        }

        if (!!entryDetails.entry && !entryDetails.isTimer) {
            this.cancelEdit(entryDetails.entry);

            return;
        }

        this.onReset(entryDetails.entry, true);
    };

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.ADD, (): void => { this._grid.onAdd(); }],
            [RegisterableShortcuts.REVERT, (): void => { if (this._checkIfChanges(false)) { this._handleReset(); } }],
            [RegisterableShortcuts.SAVE, (): void => { if (this._checkIfChanges(true)) { this._handleSave(); } }],
            [RegisterableShortcuts.EDIT, (): void => angular.noop()]]);
        this.shortcutService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.ADD, RegisterableShortcuts.REVERT, RegisterableShortcuts.EDIT])
            .pipe(takeUntil(this.destroy))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    debtorSplitView = (dataItem: TimeEntry): void => {
        this.modalService.openModal(DebtorSplitsComponent, { class: 'modal-lg', initialState: { timeEntry: dataItem } });
    };
}