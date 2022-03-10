import { fakeAsync, flush, flushMicrotasks, tick } from '@angular/core/testing';
import { WarningCheckerServiceMock } from 'accounting/warnings/warning.mock';
import { DateHelperMock } from 'ajs-upgraded-providers/mocks/date-helper.mock';
import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import * as angular from 'angular';
import { AttachmentModalServiceMock } from 'common/attachments/attachment-modal.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { ChangeDetectorRefMock, EventEmitterMock, IpxNotificationServiceMock, NgZoneMock, NotificationServiceMock, StateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { KotViewForEnum } from 'rightbarnav/keep-on-top-notes-view.service';
import { QuickNavModel } from 'rightbarnav/rightbarnav.service';
import { RightBarNavServiceMock } from 'rightbarnav/rightbarnavservice.mock';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { CaseWebLinksTaskProviderMock } from 'search/common/case-web-links-task-provider.mock';
import { EnterPressedEvent, RowState } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import * as _ from 'underscore';
import { CaseBillNarrativeComponent } from './case-bill-narrative/case-bill-narrative.component';
import { ChangeEntryDateComponent } from './change-entry-date/change-entry-date.component';
import { DuplicateEntryComponent } from './duplicate-entry/duplicate-entry.component';
import { TimeEntryEx, TimeRecordingPermissions, TimeRecordingSettings, UserIdAndPermissions, UserTaskSecurity, WipStatusEnum } from './time-recording-model';
import { TimeRecordingComponent } from './time-recording.component';
import { DuplicateEntryServiceMock, PostTimeDialogServiceMock, TimeCalculationServiceMock, TimeContinuationServiceMock, TimeGridHelperMock, TimeRecordingServiceMock, TimeSettingsServiceMock, TimesheetFormsServiceMock, UserInfoServiceMock } from './time-recording.mock';

describe('TimeRecordingComponent', () => {
    let c: TimeRecordingComponent;
    let timeService: any;
    let timeCalcService: any;
    let timeContinuationService: any;
    let notificationService: any;
    let dateHelper: any;
    let modalService: ModalServiceMock;
    let rootScopeService: any;
    let localSettings: any;
    let notificationServiceMock: IpxNotificationServiceMock;
    let navBarService: RightBarNavServiceMock;
    let cdRef: ChangeDetectorRefMock;
    let timeGridHelper: any;
    let timeSettings: any;
    let timeForms: any;
    let translateService: any;
    let userInfoService: any;
    let datepipe: any;
    let localeDate: any;
    let stateService: any;
    let duplicateService: DuplicateEntryServiceMock;
    let warningChecker: WarningCheckerServiceMock;
    let continuedTimeHelper: any;
    let postDialog: PostTimeDialogServiceMock;
    let messaging: any;
    let zone: any;
    let shortcutsService: IpxShortcutsServiceMock;
    let caseWebLinksProvider: CaseWebLinksTaskProviderMock;
    let attachmentModalService: AttachmentModalServiceMock;

    beforeEach(() => {
        timeService = new TimeRecordingServiceMock();
        timeCalcService = new TimeCalculationServiceMock();
        timeContinuationService = new TimeContinuationServiceMock();
        notificationService = new NotificationServiceMock();
        dateHelper = new DateHelperMock();
        modalService = new ModalServiceMock();
        rootScopeService = new RootScopeServiceMock();
        localSettings = new LocalSettingsMock();
        notificationServiceMock = new IpxNotificationServiceMock();
        navBarService = new RightBarNavServiceMock();
        cdRef = new ChangeDetectorRefMock();
        timeGridHelper = new TimeGridHelperMock();
        timeSettings = new TimeSettingsServiceMock();
        timeForms = new TimesheetFormsServiceMock();
        translateService = { instant: jest.fn() };
        userInfoService = new UserInfoServiceMock();
        datepipe = { transform: jest.fn() };
        localeDate = { transform: jest.fn() };
        stateService = new StateServiceMock();
        duplicateService = new DuplicateEntryServiceMock();
        warningChecker = new WarningCheckerServiceMock();
        continuedTimeHelper = {};
        postDialog = new PostTimeDialogServiceMock();
        zone = new NgZoneMock();
        shortcutsService = new IpxShortcutsServiceMock();
        caseWebLinksProvider = new CaseWebLinksTaskProviderMock();
        messaging = { subscribeToTimerMessages: jest.fn(), message$: of(null) };
        attachmentModalService = new AttachmentModalServiceMock();
        c = new TimeRecordingComponent(timeService, timeCalcService, dateHelper, { canViewReceivables: true } as any, localSettings, rootScopeService, notificationService, warningChecker as any, modalService as any, notificationServiceMock as any, navBarService as any, timeGridHelper, cdRef as any, postDialog as any, timeSettings, timeForms, translateService, userInfoService, datepipe, localeDate, stateService, duplicateService as any, continuedTimeHelper, zone, messaging, shortcutsService as any, caseWebLinksProvider as any, attachmentModalService as any);
        c.onDateChanged = jasmine.createSpy().and.callThrough();
        timeService.getViewData$ = jest.fn().mockReturnValue(of({ displaySeconds: true, localCurrencyCode: 'AUD', timeFormat12Hours: true, valueTimeOnEntry: true, defaultInfo: null }));
        localSettings.getLocal = jest.fn();
        c._grid = new IpxKendoGridComponentMock() as any;
        c._gridFocus = { refocus: jest.fn(), focusEditableField: jest.fn(), setFocusOnMasterRow: jest.fn(), focusFirstEditableField: jest.fn() } as any;
        c._gridKeyboardHandler = { onEnter: new EventEmitterMock() as any } as any;
        c._caseRef = { focus: jest.fn() } as any;
        c._nameRef = { focus: jest.fn() } as any;
        c._narrativeTitleRef = { focus: jest.fn() } as any;
        c._narrativeTextRef = { focus: jest.fn() } as any;
        c._notesRef = { focus: jest.fn() } as any;
        timeSettings.userTaskSecurity = new UserTaskSecurity({ maintainPostedTime: { edit: true } });
    });

    describe('Initialisation', () => {
        it('should set the displaySeconds and localCurrencyCode', () => {
            timeSettings.getViewData$ = jest.fn().mockReturnValue(of({ displaySeconds: true, canAdjustValues: true, localCurrencyCode: 'xyz' }));
            c.ngOnInit();
            timeSettings.getViewData$().subscribe(() => {
                expect(c.timeRecordingSettings.displaySeconds).toBe(true);
                expect(c.timeRecordingSettings.localCurrencyCode).toBe('xyz');
            });
            expect(timeService.showKeepOnTopNotes).toHaveBeenCalled();
        });

        it('should set the currentDate to todays date', () => {
            const today = new Date();
            c.ngOnInit();
            expect(c.currentDate.toDateString()).toEqual(today.toDateString());
        });

        it('should register the context menu', () => {
            c.ngOnInit();
            expect(navBarService.registercontextuals).toHaveBeenCalledWith(
                expect.objectContaining({ timeRecordingPreferences: expect.any(QuickNavModel) }));
            expect(navBarService.registercontextuals).lastCalledWith(
                expect.objectContaining({ timeGaps: expect.any(QuickNavModel) }));
        });

        it('should set the initialise the context menu for grid', fakeAsync(() => {
            timeSettings.getViewData$ = jest.fn().mockReturnValue(of({ displaySeconds: true, canAdjustValues: true, localCurrencyCode: 'xyz' }));
            timeSettings.initializeProperties = jest.fn();
            timeGridHelper.initializeTaskItems = jest.fn();

            c.ngOnInit();
            tick(100);
            expect(timeGridHelper.initializeTaskItems).toHaveBeenCalled();
        }));

        it('should consider the setting of canAdjustValues set to false', fakeAsync(() => {
            timeSettings.getViewData$ = jest.fn().mockReturnValue(of({ settings: { displaySeconds: true, localCurrencyCode: 'xyz' }, userInfo: { canAdjustValues: false } }));
            timeSettings.initializeProperties = jest.fn();
            timeGridHelper.initializeTaskItems = jest.fn();

            c.ngOnInit();
            tick(100);
            const allowedActions = timeGridHelper.initializeTaskItems.mock.calls[0][1];

            expect(_.contains(allowedActions, 'ADJUST_VALUES')).toBeFalsy();
        }));

        describe('time gaps', () => {
            it('should pass correct parameters to viewdata', (done => {
                const today = new Date();

                c.ngOnInit();
                c.displayName = 'Mr. Bing';
                c.staffNameId = 100;
                const contexts = navBarService.registercontextuals.mock.calls[0][0];

                expect(contexts.timeGaps).not.toBeNull();

                contexts.timeGaps.options.resolve.viewData().subscribe((d) => {
                    expect(d.displayName).toBe(c.displayName);
                    expect(d.userNameId).toBe(c.staffNameId);
                    expect(d.selectedDate.toDateString()).toBe(today.toDateString());

                    done();
                });
            }));

            it('should refresh the grid and put the newly added first gap in edit mode', (done => {
                const today = new Date();

                c.ngOnInit();
                c.displayName = 'Mr. Bing';
                c.staffNameId = 100;
                const contexts = navBarService.registercontextuals.mock.calls[0][0];

                expect(contexts.timeGaps).not.toBeNull();

                contexts.timeGaps.options.resolve.viewData().subscribe((d) => {
                    d.onAddition(10);

                    expect(c._grid.closeRow).toHaveBeenCalled();
                    expect(cdRef.markForCheck).toHaveBeenCalled();
                    expect(c._grid.search).toHaveBeenCalled();

                    done();
                });
            }));

            it('should put the entry in edit after dataBound, if initEntryInEdit is set', () => {
                const entry = { entryNO: 100 };
                timeService.getRowIdFor = jest.fn().mockReturnValue(2);
                timeService.getTimeEntryFromList = jest.fn().mockReturnValue(entry);
                c.initEntryInEdit = 100;
                c.ngOnInit();
                c.gridOptions = c.buildGridOptions();
                const editRowSpy = c.gridOptions.editRow = jest.fn();

                c.gridOptions.onDataBound({});
                expect(timeService.getTimeEntryFromList).toHaveBeenCalled();
                expect(timeService.getRowIdFor).toHaveBeenCalled();
                expect(editRowSpy).toHaveBeenCalledWith(2, entry);
            });
        });
        describe('if navigated into with caseId', () => {
            beforeEach(() => {
                stateService.params.caseId = -999;
                c = new TimeRecordingComponent(timeService, timeCalcService, dateHelper, { canViewReceivables: true } as any, localSettings, rootScopeService, notificationService, warningChecker as any, modalService as any, notificationServiceMock as any, navBarService as any, timeGridHelper, cdRef as any, postDialog as any, timeSettings, timeForms, translateService, userInfoService, datepipe, localeDate, stateService, duplicateService as any, continuedTimeHelper, zone, messaging, shortcutsService as any, caseWebLinksProvider as any, attachmentModalService as any);
                c.ngOnInit();
            });
            it('redirects to default time page with caseKey', () => {
                stateService.params.caseId = -999;
                c = new TimeRecordingComponent(timeService, timeCalcService, dateHelper, { canViewReceivables: true } as any, localSettings, rootScopeService, notificationService, warningChecker as any, modalService as any, notificationServiceMock as any, navBarService as any, timeGridHelper, cdRef as any, postDialog as any, timeSettings, timeForms, translateService, userInfoService, datepipe, localeDate, stateService, duplicateService as any, continuedTimeHelper, zone, messaging, shortcutsService as any, caseWebLinksProvider as any, attachmentModalService as any);
                spyOn(c, 'ngOnInit');
                expect(stateService.go.mock.calls[0][0]).toBe('timeRecordingForCase');
                expect(stateService.go.mock.calls[0][1]).toEqual({ caseKey: -999 });
                expect(c.ngOnInit).not.toHaveBeenCalled();
            });
        });

        describe('if default case is specified', () => {
            beforeEach(() => {
                stateService.params.caseKey = -999;
                timeForms.caseReference = { patchValue: jest.fn() };
                c = new TimeRecordingComponent(timeService, timeCalcService, dateHelper, { canViewReceivables: true } as any, localSettings, rootScopeService, notificationService, warningChecker as any, modalService as any, notificationServiceMock as any, navBarService as any, timeGridHelper, cdRef as any, postDialog as any, timeSettings, timeForms, translateService, userInfoService, datepipe, localeDate, stateService, duplicateService as any, continuedTimeHelper, zone, messaging, shortcutsService as any, caseWebLinksProvider as any, attachmentModalService as any);
                timeSettings.getViewData$ = jest.fn().mockReturnValue(of({ defaultInfo: { caseId: -999, caseReference: 'xyz-ABC-001' } }));
                c.ngOnInit();
            });
            it('retrieves viewData with this caseID', fakeAsync(() => {
                tick(500);
                expect(timeSettings.getViewData$).toHaveBeenCalledWith(-999, null);
                expect(c.initCaseKey).toBe(-999);
                expect(c.initCaseRef).toBe('xyz-ABC-001');
            }));
            it('adds a new row with the case defaulted', fakeAsync(() => {
                c._grid = new IpxKendoGridComponentMock() as any;
                c._caseRef = { focus: jest.fn(), search: jest.fn() } as any;
                const boundData = {
                    data: [
                        {
                            caseKey: -1,
                            entryNo: 11,
                            isUpdated: false
                        }
                    ]
                };
                tick(500);
                c.gridOptions = c.buildGridOptions();
                c.gridOptions.onDataBound(boundData);
                tick(20);
                flush();
                expect(c._grid.addRow).toHaveBeenCalled();
                expect(c.initCaseKey).toBeNull();
                expect(timeForms.caseReference.patchValue).toHaveBeenCalledWith(expect.objectContaining({ key: -999, code: 'xyz-ABC-001' }), expect.objectContaining({ emitEvent: true }));
                expect(c._caseRef.search).toHaveBeenCalledWith('xyz-ABC-001', null);
            }));
        });

        describe('when stop timer message arrives', () => {
            beforeEach(() => {
                messaging = { message$: jest.fn().mockReturnValue(of({ hasActiveTimer: false, basicDetails: { entryNo: 555, updatedEntry: { data: 'some-data' } } })) };
            });
            it('should subscribe to the timer messages', () => {
                c.ngOnInit();
                messaging.message$().subscribe(() => {
                    expect(c.resetForm).not.toHaveBeenCalled();
                    expect(timeService._applyNewData).toHaveBeenCalled();
                    expect(timeService._applyNewData.mock.calls[1][1]).toBe(555);
                    expect(timeService._applyNewData.mock.calls[1][2].data).toBe('some-data');
                    expect(timeService._applyNewData.mock.calls[1][2].isTimer).toBeFalsy();
                    expect(cdRef.detectChanges).toHaveBeenCalled();
                });
            });
            it('should reset the form if in edit', () => {
                c.ngOnInit();
                c.entryInEdit = 555;
                messaging.message$().subscribe(() => {
                    expect(c.resetForm).toHaveBeenCalled();
                    expect(timeService._applyNewData).toHaveBeenCalled();
                    expect(timeService._applyNewData.mock.calls[1][1]).toBe(555);
                    expect(timeService._applyNewData.mock.calls[1][2].data).toBe('some-data');
                    expect(timeService._applyNewData.mock.calls[1][2].isTimer).toBeFalsy();
                    expect(cdRef.detectChanges).toHaveBeenCalled();
                });
            });
        });
        describe('when auto-stopper timer message arrives', () => {
            beforeEach(() => {
                messaging = { message$: jest.fn().mockReturnValue(of({ hasActiveTimer: false, hasAutoStoppedTimer: true, basicDetails: { entryNo: 888, entryDate: new Date()} })) };
            });
            it('should subscribe to the timer messages', () => {
                c.ngOnInit();
                messaging.message$().subscribe(() => {
                    expect(c.refreshGrid).toHaveBeenCalled();
                    expect(c.resetForm).not.toHaveBeenCalled();
                    expect(timeService._applyNewData).not.toHaveBeenCalled();
                    expect(cdRef.detectChanges).toHaveBeenCalled();
                });
            });
        });
        describe('when updated timer message arrives', () => {
            beforeEach(() => {
                messaging = { message$: jest.fn().mockReturnValue(of({ hasActiveTimer: true, basicDetails: { entryNo: 555, updatedEntry: { data: 'some-data' } } })) };
            });
            it('should subscribe to the timer messages', () => {
                c.ngOnInit();
                messaging.message$().subscribe(() => {
                    expect(c.resetForm).not.toHaveBeenCalled();
                    expect(timeService._applyNewData).toHaveBeenCalled();
                    expect(timeService._applyNewData.mock.calls[1][1]).toBe(555);
                    expect(timeService._applyNewData.mock.calls[1][2].data).toBe('some-data');
                    expect(timeService._applyNewData.mock.calls[1][2].isTimer).toBeTruthy();
                    expect(cdRef.detectChanges).toHaveBeenCalled();
                });
            });
            it('should not reset the form if in edit', () => {
                c.ngOnInit();
                c.entryInEdit = 555;
                messaging.message$().subscribe(() => {
                    expect(c.resetForm).not.toHaveBeenCalled();
                    expect(timeService._applyNewData).toHaveBeenCalled();
                    expect(timeService._applyNewData.mock.calls[1][1]).toBe(555);
                    expect(timeService._applyNewData.mock.calls[1][2].data).toBe('some-data');
                    expect(timeService._applyNewData.mock.calls[1][2].isTimer).toBeTruthy();
                    expect(cdRef.detectChanges).toHaveBeenCalled();
                });
            });
        });

        describe('when copying from another entry', () => {
            let copyFromEntry = {};
            beforeEach(() => {
                copyFromEntry = { ...new TimeEntryEx(), ...{ caseKey: -100, activity: 'POP' } };
                stateService.params.copyFromEntry = copyFromEntry;
                timeForms.caseReference = { patchValue: jest.fn() };
                c = new TimeRecordingComponent(timeService, timeCalcService, dateHelper, { canViewReceivables: true } as any, localSettings, rootScopeService, notificationService, warningChecker as any, modalService as any, notificationServiceMock as any, navBarService as any, timeGridHelper, cdRef as any, postDialog as any, timeSettings, timeForms, translateService, userInfoService, datepipe, localeDate, stateService, duplicateService as any, continuedTimeHelper, zone, messaging, shortcutsService as any, caseWebLinksProvider as any, attachmentModalService as any);
                timeSettings.getViewData$ = jest.fn().mockReturnValue(of({}));
                c.ngOnInit();
            });
            it('retrieves viewData with the specified entry', fakeAsync(() => {
                tick(500);
                expect(c.copyFromEntry).toEqual(copyFromEntry);
            }));
            it('adds a new row with the details defaulted', fakeAsync(() => {
                c._grid = new IpxKendoGridComponentMock() as any;
                c._gridFocus = { focusEditableField: jest.fn() } as any;
                c._caseRef = { focus: jest.fn(), search: jest.fn() } as any;
                const boundData = {
                    data: [
                        {
                            caseKey: -1,
                            entryNo: 11,
                            isUpdated: false
                        }
                    ]
                };
                tick(500);
                c.gridOptions = c.buildGridOptions();
                c.gridOptions.onDataBound(boundData);
                tick(100);
                flush();
                expect(c._grid.addRow).toHaveBeenCalled();
                expect(c.copyFromEntry).toBeNull();
            }));
        });
    });

    describe('context menu initialization', () => {
        it('edit posted time - available if all conditions are met', () => {
            timeGridHelper.initializeTaskItems = jest.fn();

            timeSettings.userTaskSecurity = { maintainPostedTime: { edit: true } };
            timeSettings.wipSplitMultiDebtor = false;
            c.allowedActions = ['POST_TIME'];

            c.ngOnInit();

            expect(timeGridHelper.initializeTaskItems.mock.calls[1][1]).toEqual(['DUPLICATE_ENTRY', 'EDIT_TIME', 'CHANGE_ENTRY_DATE', 'SEPARATOR', 'CASE_WEBLINKS']);
        });

        it('edit posted time - not available if logged in user does not have permission for posting for selected user', () => {
            const permissions = { ...new TimeRecordingPermissions(), canRead: true, canUpdate: true };
            c.userInfo.userDetails$ = of({} as any as UserIdAndPermissions, {} as any as UserIdAndPermissions, { staffId: 10, displayName: 'A', isStaff: true, permissions });

            timeGridHelper.initializeTaskItems = jest.fn();

            timeSettings.userTaskSecurity = { maintainPostedTime: { edit: true } };
            timeSettings.wipSplitMultiDebtor = false;
            c.ngOnInit();

            expect(_.contains(timeGridHelper.initializeTaskItems.mock.calls[3][1], 'EDIT_TIME')).toBeFalsy();
            expect(_.contains(timeGridHelper.initializeTaskItems.mock.calls[3][1], 'DUPLICATE_ENTRY')).toBeTruthy();
        });

        it('edit posted time - not available if maintainPostedTime for modify is not set', () => {
            timeGridHelper.initializeTaskItems = jest.fn();

            timeSettings.userTaskSecurity = { maintainPostedTime: { edit: false } };
            timeSettings.wipSplitMultiDebtor = false;
            c.allowedActions = ['POST_TIME'];

            c.ngOnInit();

            expect(_.contains(timeGridHelper.initializeTaskItems.mock.calls[1][1], 'EDIT_TIME')).toBeFalsy();
            expect(_.contains(timeGridHelper.initializeTaskItems.mock.calls[1][1], 'DUPLICATE_ENTRY')).toBeTruthy();
        });

        it('delete posted time - available if all conditions are met', () => {
            timeGridHelper.initializeTaskItems = jest.fn();

            timeSettings.userTaskSecurity = { maintainPostedTime: { edit: true, delete: true } };
            timeSettings.wipSplitMultiDebtor = false;
            c.allowedActions = ['POST_TIME'];

            c.ngOnInit();

            expect(timeGridHelper.initializeTaskItems.mock.calls[1][1]).toEqual(['DUPLICATE_ENTRY', 'EDIT_TIME', 'CHANGE_ENTRY_DATE', 'DELETE_TIME', 'SEPARATOR', 'CASE_WEBLINKS']);
        });

        it('delete posted time - not available if edit posted time not available', () => {
            timeGridHelper.initializeTaskItems = jest.fn();

            timeSettings.userTaskSecurity = { maintainPostedTime: { edit: false, delete: true } };
            timeSettings.wipSplitMultiDebtor = false;
            c.allowedActions = ['POST_TIME'];

            c.ngOnInit();

            expect(timeGridHelper.initializeTaskItems.mock.calls[1][1]).toEqual(['DUPLICATE_ENTRY', 'SEPARATOR', 'CASE_WEBLINKS']);
        });
        it('maintain case bill narrative- available if task security not available', () => {
            timeGridHelper.initializeTaskItems = jest.fn();
            timeSettings.userTaskSecurity = { maintainPostedTime: { edit: false, delete: true } };
            c.allowedActions = ['POST_TIME'];
            c.canMaintainCaseBillNarrative = true;

            c.ngOnInit();

            expect(timeGridHelper.initializeTaskItems.mock.calls[1][1]).toEqual(['DUPLICATE_ENTRY', 'SEPARATOR', 'CASE_NARRATIVE', 'CASE_WEBLINKS']);
        });

        it('view case documents - available if permission to view documents available', () => {
            timeSettings.getViewData$ = jest.fn().mockReturnValue(of({ canViewCaseAttachments: true }));
            timeGridHelper.initializeTaskItems = jest.fn();

            c.ngOnInit();

            expect(timeGridHelper.initializeTaskItems.mock.calls[0][1]).toContain('CASE_DOCUMENTS');
            expect(timeGridHelper.initializeTaskItems.mock.calls[1][1]).toContain('CASE_DOCUMENTS');
        });

        it('view case documents - not available if permission to view documents is not available', () => {
            timeSettings.getViewData$ = jest.fn().mockReturnValue(of({ canViewCaseAttachments: false }));
            timeGridHelper.initializeTaskItems = jest.fn();

            c.ngOnInit();

            expect(timeGridHelper.initializeTaskItems.mock.calls[0][1]).not.toContain('CASE_DOCUMENTS');
            expect(timeGridHelper.initializeTaskItems.mock.calls[1][1]).not.toContain('CASE_DOCUMENTS');
        });
    });

    describe('Date navigation', () => {
        it('should set the currDate to today on click of Today', () => {
            const today = new Date();
            c.today();
            c.ngOnInit();

            expect(c.currentDate.toDateString()).toEqual(today.toDateString());
        });

        it('should set the currDate to currDate - 1 on click of Prev', () => {
            const today = new Date();
            const yesterday = new Date(today);
            yesterday.setDate(today.getDate() - 1);
            c.previous();
            expect(c.currentDate.toDateString()).toEqual(yesterday.toDateString());
        });

        it('should set the currDate to currDate + 1 on click of Next', () => {
            const today = new Date();
            const tomo = new Date(today);
            tomo.setDate(today.getDate() + 1);
            c.next();
            expect(c.currentDate.toDateString()).toEqual(tomo.toDateString());
        });
    });

    describe('Time Entry List grid', () => {
        it('sets the current date and initialises grid', () => {
            const date = new Date();
            expect(c.currentDate.toLocaleDateString()).toEqual(date.toLocaleDateString());
            c.ngOnInit();
            const grid = c.gridOptions;
            expect(grid).toBeDefined();
        });

        it('calls the list time service', () => {
            c.ngOnInit();
            c.gridOptions.read$(undefined);
            expect(timeService.getTimeList).toHaveBeenCalled();
        });

        it('the list is reloaded', () => {
            const selectedDate = new Date();
            spyOn(dateHelper, 'toLocal').and.callThrough();
            c.ngOnInit();
            const gridOptionsCloseEditMode = c.gridOptions._closeEditMode = jest.fn();
            const gridCollapseAll = c._grid.collapseAll = jest.fn();
            c._grid.closeRow = jest.fn();
            c.onDateChanged(selectedDate);
            expect(dateHelper.toLocal).toHaveBeenCalledWith(selectedDate);
            expect(c._grid.search).toHaveBeenCalled();
            expect(gridOptionsCloseEditMode).toHaveBeenCalled();
            expect(gridCollapseAll).toHaveBeenCalled();
        });
        it('sets to today\'s date', () => {
            const now = new Date();
            c.today();
            expect(c.currentDate.getFullYear()).toBe(now.getFullYear());
            expect(c.currentDate.getMonth()).toBe(now.getMonth());
            expect(c.currentDate.getDate()).toBe(now.getDate());
        });
        it('does not re-request for todays data', () => {
            const now = new Date();
            c.today();
            expect(c.currentDate.getFullYear()).toBe(now.getFullYear());
            expect(c.currentDate.getMonth()).toBe(now.getMonth());
            expect(c.currentDate.getDate()).toBe(now.getDate());
            expect(c.onDateChanged).not.toHaveBeenCalled();
        });
        it('marks isTodaySelected, based on selected date', () => {
            c.onDateChanged(new Date().setFullYear(2001));
            expect(c.isTodaySelected).toBeFalsy();
        });

        it('should initialize start time to today if siteCtrl\'s timeEmptyForNewEntries is false and timservice data is empty', () => {
            timeSettings.timeEmptyForNewEntries = false;
            timeService.timeList = null;
            timeCalcService.selectedDate = new Date();
            const startTime = timeCalcService.initializeStartTime();
            expect(startTime).not.toBeNull();
        });
    });

    describe('Component validation', () => {
        beforeEach(() => {
            timeService.checkCaseStatus = jest.fn().mockReturnValue(of(true));
        });
        it('should make component invalid for saving if current date is null', () => {
            c.currentDate = null;
            const isComponentInvalid = c.componentInvalid();
            expect(isComponentInvalid).toBe(true);
        });
    });

    describe('Saving', () => {
        it('should cancel if save button has already been clicked', () => {
            c.hasPendingSave = true;
            c.saveTime();
            expect(timeService.saveTimeEntry).not.toHaveBeenCalled();
        });
        it('should cancel if form is invalid', () => {
            timeForms.isFormValid = false;
            c.saveTime();
            expect(timeService.saveTimeEntry).not.toHaveBeenCalled();
        });
        it('should call time service\'s save on click of save', () => {
            timeService.timeList = { data: [] };
            timeForms.getDataToSave = jest.fn().mockReturnValue({ data: 'someStuff' });
            timeService.saveTimeEntry = jest.fn().mockReturnValue(of({ response: 101 }));
            c.ngOnInit();
            const closeRowSpy = c._grid.closeRow = jest.fn();
            c.saveTime();
            expect(timeForms.defaultFinishTime).toHaveBeenCalled();
            timeService.saveTimeEntry().subscribe(() => {
                expect(notificationService.success).toHaveBeenCalled();
                expect(c._grid.search).toHaveBeenCalled();
                expect(closeRowSpy).toHaveBeenCalled();
                expect(timeForms.resetForm).toHaveBeenCalled();
                expect(c.hasPendingSave).toBe(false);
            });
            expect(timeService.saveTimeEntry).toHaveBeenCalled();
            expect(c.gridOptions.enableGridAdd).toBe(true);
            expect(c._grid.search).toHaveBeenCalled();
            expect(closeRowSpy).toHaveBeenCalled();
        });

        it('isSavedEntry returns appropriate result, if saved entry', () => {
            let isSaved = c.isSavedEntry(10);
            expect(isSaved).toBeTruthy();

            isSaved = c.isSavedEntry(0);
            expect(isSaved).toBeTruthy();

            isSaved = c.isSavedEntry(null);
            expect(isSaved).toBeFalsy();

            isSaved = c.isSavedEntry(undefined);
            expect(isSaved).toBeFalsy();
        });
    });

    describe('Deleting for different timezones', () => {
        const dataItem = new TimeEntryEx({
            caseKey: -457,
            entryNo: 20
        });
        beforeEach(() => {
            c.ngOnInit();
            c._grid.closeRow = jest.fn();
            c.gridOptions._closeEditMode = jest.fn();
            timeService.deleteTimeEntry = jest.fn(() => {
                return of({});
            }).mockName('timeService.deleteTimeEntry');
            timeService.deleteContinuedChain = jest.fn(() => {
                return of({});
            }).mockName('timeService.deleteContinuedChain');
            notificationServiceMock.modalRef.content = {
                confirmed$: of('confirm'),
                cancelled$: of()
            };
        });
        it('should call time service\'s delete using America/New_York date', () => {
            const entryDate = new Date(new Date().toLocaleString('en-US', { timeZone: 'America/New_York' }));
            c.onDateChanged(entryDate);
            c.deleteTime(dataItem);
            expect(timeService.deleteTimeEntry.mock.calls[0][0].entryDate).toEqual(entryDate);
        });
        it('should call time service\'s delete using Australia/Adelaide date', () => {
            const entryDate = new Date(new Date().toLocaleString('en-US', { timeZone: 'Australia/Adelaide' }));
            c.onDateChanged(entryDate);
            c.deleteTime(dataItem);
            expect(timeService.deleteTimeEntry.mock.calls[0][0].entryDate).toEqual(entryDate);
        });
        it('should call time service\'s delete using Europe/London date', () => {
            const entryDate = new Date(new Date().toLocaleString('en-US', { timeZone: 'Europe/London' }));
            c.onDateChanged(entryDate);
            c.deleteTime(dataItem);
            expect(timeService.deleteTimeEntry.mock.calls[0][0].entryDate).toEqual(entryDate);
        });
        it('should call time service\'s delete using America/Los Angeles date', () => {
            const entryDate = new Date(new Date().toLocaleString('en-US', { timeZone: 'America/Los_Angeles' }));
            c.onDateChanged(entryDate);
            c.deleteTime(dataItem);
            expect(timeService.deleteTimeEntry.mock.calls[0][0].entryDate).toEqual(entryDate);
        });
    });

    describe('Deleting', () => {
        beforeEach(() => {
            c.ngOnInit();
            c._grid.closeRow = jest.fn();
            timeService.deleteTimeEntry = jest.fn(() => {
                return of({});
            }).mockName('timeService.deleteTimeEntry');
            timeService.deleteContinuedChain = jest.fn(() => {
                return of({});
            }).mockName('timeService.deleteContinuedChain');
        });
        it('should call time service\'s delete and refresh the grid', fakeAsync(() => {
            notificationServiceMock.modalRef.content = {
                confirmed$: of('confirm'),
                cancelled$: of()
            };
            const dataItem = new TimeEntryEx({
                caseKey: -457,
                entryNo: 20
            });
            c.deleteTime(dataItem);
            tick();
            expect(timeService.deleteTimeEntry).toHaveBeenCalled();
            expect(c._grid.search).toHaveBeenCalled();
            expect(notificationServiceMock.openDeleteConfirmModal).toHaveBeenCalledWith('accounting.time.recording.deleteTime', null, false, null);
        }));
        it('should delete continued chain where specified', fakeAsync(() => {
            notificationServiceMock.modalRef.content = {
                confirmed$: of('confirmApply'),
                cancelled$: of()
            };
            const dataItem = new TimeEntryEx({
                caseKey: -457,
                entryNo: 20,
                parentEntryNo: 1234,
                childEntryNo: null
            });
            c.deleteTime(dataItem);
            tick();
            expect(timeService.deleteContinuedChain).toHaveBeenCalled();
            expect(c._grid.search).toHaveBeenCalled();
            expect(notificationServiceMock.openDeleteConfirmModal).toHaveBeenCalledWith('accounting.time.recording.validationMsgs.deleteContinuedEntry', null, true, 'accounting.time.recording.deleteContinuedChain');

            dataItem.childEntryNo = 987;
            c.deleteTime(dataItem);
            tick();
            expect(timeService.deleteContinuedChain).toHaveBeenCalled();
            expect(c._grid.search).toHaveBeenCalled();
            expect(notificationServiceMock.openDeleteConfirmModal).toHaveBeenCalledWith('accounting.time.recording.validationMsgs.deleteContinuedEntry', null, true, 'accounting.time.recording.deleteContinuedChain');
        }));
        it('should perform checks if entry is editable and display confirmation, if posted entry is being deleted', () => {
            timeService.canPostedEntryBeEdited = jest.fn().mockReturnValue(of(WipStatusEnum.Editable));
            const dataItem = new TimeEntryEx({
                caseKey: -457,
                entryNo: 20,
                parentEntryNo: 1234,
                childEntryNo: null,
                staffId: 100,
                isPosted: true
            });
            c.deleteTime(dataItem);

            expect(timeService.canPostedEntryBeEdited).toHaveBeenCalledWith(20, 100);
            expect(notificationServiceMock.openDeleteConfirmModal).toHaveBeenCalled();
            expect(notificationServiceMock.openDeleteConfirmModal.mock.calls[0][0]).toBe('accounting.time.recording.validationMsgs.deletePostedContinuedEntry');
        });

        it('for posted continued parent, do not perform check if entry is editable and display correct confirmation dialog', () => {
            const dataItem = new TimeEntryEx({
                caseKey: -457,
                entryNo: 20,
                parentEntryNo: 1234,
                childEntryNo: null,
                staffId: 101,
                isPosted: true,
                isContinuedParent: true
            });
            c.deleteTime(dataItem);

            expect(notificationServiceMock.openDeleteConfirmModal).toHaveBeenCalled();
            expect(notificationServiceMock.openDeleteConfirmModal.mock.calls[0][0]).toBe('accounting.time.recording.validationMsgs.deletePostedContinuedEntry');
            expect(notificationServiceMock.openDeleteConfirmModal.mock.calls[0][3]).toBe('accounting.time.recording.deletePostedContinuedChain');
        });

        it('should not proceed with delete if the corresponding wip if billed for the posted entry being deleted', () => {
            timeService.canPostedEntryBeEdited = jest.fn().mockReturnValue(of(WipStatusEnum.Billed));
            const dataItem = new TimeEntryEx({
                caseKey: -457,
                entryNo: 20,
                parentEntryNo: 1234,
                childEntryNo: null,
                staffId: 100,
                isPosted: true
            });
            c.deleteTime(dataItem);

            expect(timeService.canPostedEntryBeEdited).toHaveBeenCalledWith(20, 100);
            expect(notificationServiceMock.openAlertModal).toHaveBeenCalled();
            expect(notificationServiceMock.openAlertModal.mock.calls[0][1]).toBe('accounting.time.editPostedTime.billedError');
            expect(notificationServiceMock.openDeleteConfirmModal).not.toHaveBeenCalled();
        });

        it('should display error, if API returns error', fakeAsync(() => {
            timeService.deleteTimeEntry = jest.fn(() => {
                return of({ error: { alertID: 'ABCD' } });
            });
            translateService.instant = jest.fn().mockReturnValue('translated-ABC123');

            notificationServiceMock.modalRef.content = {
                confirmed$: of('confirm'),
                cancelled$: of()
            };
            const dataItem = new TimeEntryEx({
                caseKey: -457,
                entryNo: 20
            });
            c.deleteTime(dataItem);
            tick();
            expect(timeService.deleteTimeEntry).toHaveBeenCalled();
            expect(translateService.instant).toHaveBeenCalledWith('accounting.errors.ABCD');
            expect(notificationServiceMock.openAlertModal).toHaveBeenCalled();
            expect(c._grid.search).not.toHaveBeenCalled();
        }));
    });

    describe('On Row Added', () => {
        const settings: TimeRecordingSettings = {
            displaySeconds: true,
            timeEmptyForNewEntries: true,
            restrictOnWip: true,
            addEntryOnSave: true,
            localCurrencyCode: 'xyz',
            timeFormat12Hours: true,
            hideContinuedEntries: true,
            continueFromCurrentTime: true,
            unitsPerHour: 10,
            roundUpUnits: true,
            considerSecsInUnitsCalc: true,
            enableUnitsForContinuedTime: true,
            valueTimeOnEntry: true,
            canAdjustValues: true,
            canFunctionAsOtherStaff: true,
            wipSplitMultiDebtor: false
        };

        beforeEach(() => {
            timeService.checkCaseStatus = jest.fn().mockReturnValue(of(true));
        });
        it('should show a dialog if the selected year is diff to current year when session value to hide is false', () => {
            c.currentDate = null;
            timeService.timeList = { data: null };
            c.gridOptions = c.buildGridOptions();
            c.gridOptions.navigateByIndex = jest.fn();
            c._grid.wrapper.expandRow = jest.fn();

            c.localSettings.keys.accounting.timesheet.hideFutureYearWarning.getSessionValue = jest.fn(() => false);
            const dlgSpy = c.showDifferentYearWarning = jest.fn();
            c.onRowAdded();
            expect(dlgSpy).toHaveBeenCalled();
        });
        it('should not show the dialog if when the session value to hide is true', () => {
            timeService.timeList = { data: null };
            c.localSettings.keys.accounting.timesheet.hideFutureYearWarning.getSessionValue = jest.fn(() => true);
            const dlgSpy = c.showDifferentYearWarning = jest.fn();
            c._grid.wrapper.expandRow = jest.fn();
            c.selectedCaseKey = null;
            c.gridOptions = c.buildGridOptions();
            c.gridOptions.navigateByIndex = jest.fn();
            c.onRowAdded();
            expect(dlgSpy).not.toHaveBeenCalled();
        });
        it('should set session to true when the hide warning dialog\'s ok is clicked & session is checked', () => {
            modalService.openModal = jest.fn(() => {
                return { hide: null, content: { okClicked: of(true) }, setClass: null };
            });
            const sessionSpy = c.localSettings.keys.accounting.timesheet.hideFutureYearWarning.setSession = jest.fn(() => true);
            c.showDifferentYearWarning();
            expect(sessionSpy).toHaveBeenCalledWith(true);
        });
        it('should not set session when the hide warning dialog\'s ok clicked without session check', () => {
            const sessionSpy = c.localSettings.keys.accounting.timesheet.hideFutureYearWarning.setSession = jest.fn();
            c.showDifferentYearWarning();
            expect(sessionSpy).not.toHaveBeenCalled();
        });
        it('should select the last added row and raise an event with selected Case key', fakeAsync(() => {
            c.initCaseKey = null;
            c.timeRecordingSettings = settings;
            const boundData = [
                {
                    caseKey: -1,
                    entryNo: 11,
                    isUpdated: false
                },
                {
                    caseKey: -2,
                    entryNo: 12,
                    isUpdated: false
                },
                {
                    caseKey: -3,
                    entryNo: 13,
                    isUpdated: true
                },
                {
                    caseKey: -4,
                    entryNo: 14,
                    isUpdated: false
                },
                {
                    caseKey: -5,
                    entryNo: 15,
                    isUpdated: false
                }
            ];
            c.selectedCaseKey = null;
            c.gridOptions = c.buildGridOptions();
            c.gridOptions._closeEditMode = jest.fn();
            c.updatedEntryNo = 1; // some number
            c.gridOptions.onDataBound(boundData);
            tick(20);
            flush();
            expect(c._gridFocus.setFocusOnMasterRow).toHaveBeenCalledWith(2, 1);
            expect(c._grid.navigateByIndex).toHaveBeenCalledWith(2);
        }));

        describe('On Add Cancelled', () => {
            it('closes the added row', () => {
                const resetSpy = c.resetForm = jest.fn();
                timeForms.hasPendingChanges = false;
                timeService.timeList = [{ entryNo: 1 }];
                c.ngOnInit();
                c.gridOptions = c.buildGridOptions();
                c.gridOptions.removeRow = jest.fn();
                c.cancelAdd();
                expect(c.gridOptions.enableGridAdd).toBe(true);
                expect(resetSpy).toHaveBeenCalled();
                expect(c._grid.gridMessage).not.toBeDefined();
            });
            it('closes the added row and sets message if there are no entries', () => {
                const resetSpy = c.resetForm = jest.fn();
                timeForms.hasPendingChanges = false;
                timeService.timeList = [];
                c.ngOnInit();
                c.gridOptions = c.buildGridOptions();
                c.gridOptions.removeRow = jest.fn();
                c.cancelAdd();
                expect(c.gridOptions.enableGridAdd).toBe(true);
                expect(resetSpy).toHaveBeenCalled();
                expect(c._grid.gridMessage).toBe('noResultsFound');
            });
        });
    });

    describe('On Case Changed', () => {
        beforeEach(() => {
            timeForms.caseReference = { setValue: jest.fn() };
            timeForms.name = { setValue: jest.fn() };
            timeForms.activity = { setValue: jest.fn() };
        });

        it('should set the name, after case is selected', () => {
            c.onCaseChanged({ key: 10, instructorName: 'abcd', instructorNameId: 100 }, false);

            expect(timeForms.name.setValue).toHaveBeenCalled();
            expect(timeForms.name.setValue.mock.calls[0][0]).toEqual({ key: 100, displayName: 'abcd' });
        });

        it('should set case reference and perform proceed flow, if warnings shown are proceeded', fakeAsync(() => {
            warningChecker.performCaseWarningsCheckResult = of(true);

            c.onCaseChanged({ key: 10 }, false);
            tick();

            expect(c._gridFocus.refocus).toHaveBeenCalled();
            expect(timeForms.checkIfActivityCanBeDefaulted).toHaveBeenCalledWith(10);
            expect(timeForms.evaluateTime).toHaveBeenCalled();

            expect(timeService.rowSelected.next).toHaveBeenCalledWith(10);
            expect(timeService.rowSelectedForKot.next).toHaveBeenCalledWith({ id: 10, type: KotViewForEnum.Case });
        }));

        it('should not set case reference and perform cancel flow, if warnings are not proceeded', fakeAsync(() => {
            warningChecker.performCaseWarningsCheckResult = of(false);

            c.onCaseChanged({ key: 10 }, false);
            tick();
            expect(c.selectedCaseKey).toBeNull();
            expect(timeForms.caseReference.setValue).toHaveBeenCalled();
            expect(timeForms.caseReference.setValue.mock.calls[0][0]).toBeNull();

            expect(timeForms.name.setValue).toHaveBeenCalled();
            expect(timeForms.name.setValue.mock.calls[0][0]).toBeNull();

            expect(c._caseRef.focus).toHaveBeenCalled();
        }));
    });

    describe('Filter case selection by name', () => {
        beforeEach(() => {
            timeForms.caseReference = { setValue: jest.fn() };
            timeForms.name = { setValue: jest.fn() };
        });
        it('should clear the name when case is cleared', () => {
            c.onCaseChanged(null);
            expect(timeForms.name.setValue).toHaveBeenCalledWith(null, { emitEvent: false });
            expect(timeForms.evaluateTime).toHaveBeenCalled();
        });
        it('should clear the case when the name is changed', () => {
            timeService.getDefaultActivityFromCase = jest.fn();
            timeForms.name.setValue('originalName');
            timeForms.caseReference.setValue('originalCase');
            c.onNameChanged('newName');
            expect(timeForms.caseReference.setValue).toHaveBeenCalledWith(null, { emitEvent: false });
        });
    });

    describe('Incomplete entry', () => {
        it('should show the right error msg', () => {
            timeService.getViewData$ = jest.fn().mockReturnValue(of({ displaySeconds: true, localCurrencyCode: 'AUD', showRateMandatoryText: true }));
            c.ngOnInit();
            expect(c.incompleteEntryText).toContain('incompleteEntry');
        });
    });

    describe('Name changed', () => {
        beforeEach(() => {
            timeForms.caseReference = { value: null, setValue: jest.fn() };
            timeForms.name = { value: 'abcd', setValue: jest.fn() };
        });

        it('should call warning checker, if case is null & valid name picked', () => {
            warningChecker.performNameWarningsCheckResult = of({});
            c.onNameChanged({ key: 1, displayName: 'some key' });
            expect(warningChecker.performNameWarningsCheck).toHaveBeenCalled();
            expect(warningChecker.performNameWarningsCheck.mock.calls[0][0]).toEqual(1);
            expect(warningChecker.performNameWarningsCheck.mock.calls[0][1]).toEqual('some key');
            expect(warningChecker.performNameWarningsCheck.mock.calls[0][2]).toEqual(c.currentDate);

            expect(navBarService.registerKot).toHaveBeenCalledWith(null);
        });

        it('should perform proceed flow, if warnings are proceeded', fakeAsync(() => {
            warningChecker.performNameWarningsCheckResult = of(true);

            c.onNameChanged({ key: 1, displayName: 'some key' });
            tick();
            expect(c._gridFocus.refocus).toHaveBeenCalled();
            expect(timeForms.defaultNarrativeFromActivity).toHaveBeenCalled();
            expect(timeForms.evaluateTime).toHaveBeenCalled();
            expect(timeService.rowSelectedForKot.next).toHaveBeenCalledWith({ id: 1, type: KotViewForEnum.Name });
        }));

        it('should perform cancel flow, if warnings are cancelled', fakeAsync(() => {
            warningChecker.performNameWarningsCheckResult = of(false);
            c.onNameChanged({ key: 1, displayName: 'some key' });
            expect(timeForms.name.setValue).toHaveBeenCalledWith(null, { emitEvent: false });
            expect(c._nameRef.focus).toHaveBeenCalled();
        }));
    });

    describe('Edit time', () => {
        beforeEach(() => {
            c._grid.closeRow = jest.fn();
        });
        it('should call grid options editRow & components loadFormData when edit is clicked', () => {
            c.ngOnInit();
            const editRowSpy = c.gridOptions.editRow = jest.fn();
            timeService.getRowIdFor = jest.fn().mockReturnValue(2);
            const event = { entryNo: 1, rowId: 2, narrativeText: '' };
            c.editTime(event);
            expect(editRowSpy).toHaveBeenCalledWith(2, event);
            expect(c.defaultedNarrativeText).toEqual(event.narrativeText);
        });
        it('should popup a dialog when during edit mode an other row\'s edit is clicked', () => {
            c.ngOnInit();
            c.gridOptions.enableGridAdd = false;
            c.gridOptions.editRow = jest.fn();
            const event = { entryNo: 1, rowId: 2, narrativeText: '' };
            const modalServiceSpy = notificationServiceMock.openDiscardModal.mockReturnValue({ content: { confirmed$: of(), cancelled$: of() } });
            timeForms.hasPendingChanges = true;
            c.editTime(event);
            expect(modalServiceSpy).toHaveBeenCalled();
        });
        it('should close edit mode & reset form when discard popup\'s discard button is clicked', () => {
            c.ngOnInit();
            c.gridOptions.enableGridAdd = false;
            c.gridOptions.editRow = jest.fn();
            const closeEditModespy = c.gridOptions._closeEditMode = jest.fn();
            const resetFormspy = c.resetForm = jest.fn();
            const event = { entryNo: 1, rowId: 2, narrativeText: '' };
            notificationServiceMock.openDiscardModal.mockReturnValue({ content: { confirmed$: of(), cancelled$: of() } });
            timeForms.hasPendingChanges = true;
            c.editTime(event);
            c.modalRef.content.confirmed$.subscribe(() => {
                expect(closeEditModespy).toHaveBeenCalled();
                expect(resetFormspy).toHaveBeenCalled();
            });
        });
        it('should remove the newly added unsaved row if edit is clicked on another row', () => {
            c.ngOnInit();
            timeForms.hasPendingChanges = false;
            c.hasAddedRow = true;
            c.gridOptions.enableGridAdd = false;
            c.gridOptions.editRow = jest.fn();
            const removeRowSpy = c.gridOptions.removeRow = jest.fn();
            modalService.openModal = jest.fn(() => {
                return { hide: null, content: { okClicked: of(true) }, setClass: null };
            });
            c.editTime({ rowId: 1 });
            expect(c._grid.closeRow).toHaveBeenCalled();
            expect(removeRowSpy).toHaveBeenCalled();
        });
        it('should call reset form when a row is in edit mode and an other row edit is clicked', () => {
            c.ngOnInit();
            timeForms.hasPendingChanges = false;
            c.gridOptions.enableGridAdd = false;
            c.gridOptions.editRow = jest.fn();
            const resetFormSpy = c.resetForm = jest.fn();
            c.editTime({ rowId: 1 });
            expect(resetFormSpy).toHaveBeenCalled();
        });

        it('should reset form if timer is running', () => {
            c.ngOnInit();

            c.formsService.isTimerRunning = true;
            c.hasAddedRow = true;
            c.gridOptions.editRow = jest.fn();
            const resetSpy = jest.spyOn(c, 'resetForm');

            c.editTime({ rowId: 1 });

            expect(resetSpy).toHaveBeenCalled();
            expect(c.hasAddedRow).toBeFalsy();
        });

        it('should not enter edit mode, on enter, if conditions are not fulfilled', () => {
            c.ngOnInit();
            timeForms.createFormGroup = jest.fn();
            c.gridOptions.editRow = jest.fn();
            c.ngAfterViewInit();
            const event = { entryNo: 10 };

            c._gridKeyboardHandler.onEnter.emit(new EnterPressedEvent(event as any, new RowState(true, true), 1));
            expect(c.gridOptions.editRow).not.toHaveBeenCalled();

            c._gridKeyboardHandler.onEnter.emit(new EnterPressedEvent({ entryNo: 10, isPosted: true } as any, new RowState(true, true), 1));
            expect(c.gridOptions.editRow).not.toHaveBeenCalled();

            c._gridKeyboardHandler.onEnter.emit(new EnterPressedEvent({ entryNo: 10, isContinuedParent: true } as any, new RowState(true, true), 1));
            expect(c.gridOptions.editRow).not.toHaveBeenCalled();

            c._gridKeyboardHandler.onEnter.emit(new EnterPressedEvent({ entryNo: null } as any, new RowState(true, true), 1));
            expect(c.gridOptions.editRow).not.toHaveBeenCalled();

            c.entryInEdit = 100;
            c._gridKeyboardHandler.onEnter.emit(new EnterPressedEvent({ entryNo: 100 }, new RowState(true, false), -1));
            expect(c.gridOptions.editRow).not.toHaveBeenCalled();

            c._gridKeyboardHandler.onEnter.emit(new EnterPressedEvent(event, new RowState(false, false), 1));
            expect(c.gridOptions.editRow).toHaveBeenCalled();
        });
        it('should enter edit mode and set focus on selected column', () => {
            c.ngOnInit();
            timeForms.createFormGroup = jest.fn();
            c.gridOptions.editRow = jest.fn();
            c.ngAfterViewInit();

            c._gridKeyboardHandler.onEnter.emit(new EnterPressedEvent({ entryNo: 10 }, new RowState(true, false), 1));
            expect(c.gridOptions.editRow).toHaveBeenCalled();
            c.createFormGroup(new TimeEntryEx({ entryNo: 10 }));
            expect(timeForms.createFormGroup).toHaveBeenCalled();
            expect(c._gridFocus.focusEditableField).toHaveBeenCalledWith(1);
        });

        it('should enter edit mode and do not manipulate focus', () => {
            c.ngOnInit();
            timeForms.createFormGroup = jest.fn();
            c.gridOptions.editRow = jest.fn();
            c.ngAfterViewInit();

            c._gridKeyboardHandler.onEnter.emit(new EnterPressedEvent({ entryNo: 10 }, new RowState(true, false), -1));
            expect(c.gridOptions.editRow).toHaveBeenCalled();
            c.createFormGroup(new TimeEntryEx({ entryNo: 10 }));
            expect(c._gridFocus.focusEditableField).not.toHaveBeenCalledWith(1);
        });

        it('should call the setFocusFunction if provided', () => {
            c.ngOnInit();
            c.gridOptions.editRow = jest.fn();
            const setFocus = jest.fn();
            timeService.getRowIdFor = jest.fn().mockReturnValue(2);
            const event = { entryNo: 1, rowId: 2, narrativeText: '' };
            c.editTime(event, setFocus);
            expect(setFocus).toHaveBeenCalled();
        });
        it('handleClickNarrativeTitle should call editTime and set focus on narrativeTitle', fakeAsync(() => {
            c.ngOnInit();
            c.gridOptions.editRow = jest.fn();
            timeService.getRowIdFor = jest.fn().mockReturnValue(2);
            const event = new TimeEntryEx({ entryNo: 1, rowId: 2, narrativeText: '' });
            c.handleClickNarrativeTitle(event);
            tick(20);
            expect(c._narrativeTitleRef.focus).toHaveBeenCalled();
        }));
        it('handleClickNarrativeText should call editTime and set focus on narrativeTitle', fakeAsync(() => {
            c.ngOnInit();
            c.gridOptions.editRow = jest.fn();
            timeService.getRowIdFor = jest.fn().mockReturnValue(2);
            const event = new TimeEntryEx({ entryNo: 1, rowId: 2, narrativeText: '' });
            c.handleClickNarrativeText(event);
            tick(20);
            expect(c._narrativeTextRef.focus).toHaveBeenCalled();
        }));
        it('handleClickNotes should call editTime and set focus on narrativeTitle', fakeAsync(() => {
            c.ngOnInit();
            c.gridOptions.editRow = jest.fn();
            timeService.getRowIdFor = jest.fn().mockReturnValue(2);
            const event = new TimeEntryEx({ entryNo: 1, rowId: 2, narrativeText: '' });
            c.handleClickNotes(event);
            tick(20);
            expect(c._notesRef.focus).toHaveBeenCalled();
        }));
    });

    describe('Edit posted time', () => {
        beforeEach(() => {
            c._grid.closeRow = jest.fn();
        });
        it('should call grid options editRow, if posted entry is editable and user provides confirmation to proceed', () => {
            c.ngOnInit();
            const editRowSpy = c.gridOptions.editRow = jest.fn();
            timeService.getRowIdFor = jest.fn().mockReturnValue(2);
            notificationServiceMock.openConfirmationModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true) } });

            const event = { entryNo: 1, isPosted: true, staffId: 9 };
            c.editTime(event);

            expect(timeService.canPostedEntryBeEdited).toHaveBeenCalledWith(1, 9);
            expect(editRowSpy).toHaveBeenCalledWith(2, event);
        });

        it('should not call grid options editRow, if posted entry is editable but user does not provide confirmation to proceed', () => {
            c.ngOnInit();
            const editRowSpy = c.gridOptions.editRow = jest.fn();

            const event = { entryNo: 1, isPosted: true, staffId: 9 };
            c.editTime(event);

            expect(timeService.canPostedEntryBeEdited).toHaveBeenCalledWith(1, 9);
            expect(editRowSpy).not.toHaveBeenCalled();
        });

        it('should not call grid options editRow, if posted entry is not editable', () => {
            c.ngOnInit();
            const editRowSpy = c.gridOptions.editRow = jest.fn();
            timeService.canPostedEntryBeEdited = jest.fn().mockReturnValue(of(WipStatusEnum.Billed));

            const event = { entryNo: 1, isPosted: true, staffId: 9 };
            c.editTime(event);

            expect(timeService.canPostedEntryBeEdited).toHaveBeenCalledWith(1, 9);
            expect(editRowSpy).not.toHaveBeenCalled();
        });

        it('should display appropriate error, if posted entry not editable', () => {
            c.ngOnInit();
            timeService.canPostedEntryBeEdited = jest.fn().mockReturnValueOnce(of(WipStatusEnum.Billed)).mockReturnValueOnce(of(WipStatusEnum.Locked)).mockReturnValueOnce(of(WipStatusEnum.Adjusted));

            c.editTime({ entryNo: 1, isPosted: true, staffId: 9 });
            expect(notificationServiceMock.openAlertModal).toHaveBeenCalledWith(null, 'accounting.time.editPostedTime.billedError');

            c.editTime({ entryNo: 1, isPosted: true, staffId: 9 });
            expect(notificationServiceMock.openAlertModal).toHaveBeenCalledWith(null, 'accounting.time.editPostedTime.lockedError');

            c.editTime({ entryNo: 1, isPosted: true, staffId: 9 });
            expect(notificationServiceMock.openAlertModal).toHaveBeenCalledWith(null, 'accounting.time.editPostedTime.adjustedError');
        });
    });

    describe('Update time', () => {
        beforeEach(() => {
            timeForms.getDataToSave = jest.fn().mockReturnValue({});
            c.currentDate = new Date();
            c.ngOnInit();
        });
        it('should call grid options editRow & components loadFormData when edit is clicked', () => {
            const updateTimeSpy = timeService.updateTimeEntry = jest.fn().mockReturnValue(of({ response: { entryNo: 2 } }));
            c.updateTime({ entryNo: 2, parentEntryNo: 1 } as any);
            expect(timeForms.defaultFinishTime).toHaveBeenCalled();
            expect(timeForms.getDataToSave).toHaveBeenCalled();
            expect(updateTimeSpy).toHaveBeenCalledWith({ entryNo: 2 });
            timeService.updateTimeEntry().subscribe(() => {
                expect(notificationServiceMock.success).toHaveBeenCalled();
                expect(c.resetForm).toHaveBeenCalled();
                expect(c._grid.search).toHaveBeenCalled();
            });
        });
        it('should display any errors from alertID and return', () => {
            const updateTimeSpy = timeService.updateTimeEntry = jest.fn().mockReturnValue(of({ error: { alertID: 'ABC123' } }));
            translateService.instant = jest.fn().mockReturnValue('translated-ABC123');
            c.updateTime({ entryNo: 2, parentEntryNo: 1 } as any);
            expect(timeForms.defaultFinishTime).toHaveBeenCalled();
            expect(timeForms.getDataToSave).toHaveBeenCalled();
            expect(updateTimeSpy).toHaveBeenCalledWith({ entryNo: 2 });
            timeService.updateTimeEntry().subscribe(() => {
                expect(translateService.instant).toHaveBeenCalledWith('accounting.errors.ABC123');
                expect(notificationServiceMock.openAlertModal).toHaveBeenCalledWith(null, 'translated-ABC123');
                expect(notificationServiceMock.success).not.toHaveBeenCalled();
                expect(c.resetForm).not.toHaveBeenCalled();
                expect(c._grid.search).not.toHaveBeenCalled();
            });
        });
        it('should display any custom errors and return', () => {
            const updateTimeSpy = timeService.updateTimeEntry = jest.fn().mockReturnValue(of({ error: 'OMG' }));
            translateService.instant = jest.fn().mockReturnValue('translated-ABC123');
            c.updateTime({ entryNo: 2, parentEntryNo: 1 } as any);
            expect(timeForms.defaultFinishTime).toHaveBeenCalled();
            expect(timeForms.getDataToSave).toHaveBeenCalled();
            expect(updateTimeSpy).toHaveBeenCalledWith({ entryNo: 2 });
            timeService.updateTimeEntry().subscribe(() => {
                expect(translateService.instant).toHaveBeenCalledWith('accounting.errors.OMG');
                expect(notificationServiceMock.openAlertModal).toHaveBeenCalledWith(null, 'translated-ABC123');
                expect(notificationServiceMock.success).not.toHaveBeenCalled();
                expect(c.resetForm).not.toHaveBeenCalled();
                expect(c._grid.search).not.toHaveBeenCalled();
            });
        });
    });

    describe('Cancel Edit', () => {
        it('should close edit mode when cancel edit is clicked', () => {
            const resetSpy = c.resetForm = jest.fn();
            timeForms.hasPendingChanges = false;
            c.ngOnInit();
            c.cancelEdit(null);
            expect(c.gridOptions.enableGridAdd).toBe(true);
            expect(resetSpy).toHaveBeenCalledWith(false);
        });
        it('should show popup when form is dirty and cancel edit is clicked', () => {
            c.ngOnInit();
            timeForms.hasPendingChanges = true;
            const bsmodalSpy = notificationServiceMock.openDiscardModal.mockReturnValue({ content: { confirmed$: of(), cancelled$: of({}) } });
            c.cancelEdit(null);
            expect(bsmodalSpy).toHaveBeenCalled();
        });
        it('should reset to previous values when cancel edit is clicked and popups ok is clicked', () => {
            const resetSpy = c.resetForm = jest.fn();
            c.ngOnInit();
            c.originalDetails = {
                notes: 'abc',
                narrativeText: '123',
                narrativeTitle: 'xyz'
            };
            const dataItem = {
                notes: 'abcdef',
                narrativeText: '123-456',
                narrativeTitle: 'uvwxyz'
            };
            timeForms.hasPendingChanges = true;
            notificationServiceMock.openDiscardModal.mockReturnValue({ content: { confirmed$: of(), cancelled$: of({}) } });
            c.cancelEdit(null);
            c.modalRef.content.confirmed$.subscribe(() => {
                expect(dataItem.notes).toEqual('abc');
                expect(dataItem.narrativeText).toEqual('123');
                expect(dataItem.narrativeTitle).toEqual('xyz');
                expect(c.entryInEdit).toBeNull();
                expect(c.gridOptions.enableGridAdd).toBe(true);
                expect(resetSpy).toHaveBeenCalled();
            });
        });
    });

    describe('Change Entry Date', () => {
        it('should open the modal', () => {
            c.ngOnInit();
            const selectedItem = new TimeEntryEx({ caseKey: 1234, caseReference: '1234-abc-xyz', isLastChild: true });
            c.currentDate = new Date(2000, 10, 10);
            c.changeEntryDate(selectedItem);
            expect(modalService.openModal).toHaveBeenCalled();
            expect(modalService.openModal.mock.calls[0][0]).toEqual(ChangeEntryDateComponent);
            expect(modalService.openModal.mock.calls[0][1].initialState.item).toEqual(selectedItem);
            expect(modalService.openModal.mock.calls[0][1].initialState.initialDate).toEqual(c.currentDate);
            expect(modalService.openModal.mock.calls[0][1].initialState.isContinued).toEqual(selectedItem.isLastChild);
            expect(JSON.stringify(modalService.openModal.mock.calls[0][1].initialState.openPeriods)).toEqual(JSON.stringify(of({})));

            const newDate = new Date(2000, 10, 1);
            c.modalRef.content.saveClicked.subscribe(() => {
                expect(timeService.updateDate).toHaveBeenCalledWith(newDate, selectedItem);
            });
        });

        it('for posted items, open periods are provided to modal', fakeAsync(() => {
            timeService.canPostedEntryBeEdited = jest.fn().mockReturnValue(of(WipStatusEnum.Editable));

            const selectedItem = new TimeEntryEx({ caseKey: 1234, caseReference: '1234-abc-xyz', isLastChild: true, isPosted: true, entryNo: 1, staffId: 9 });
            c.currentDate = new Date(2000, 10, 10);
            c.changeEntryDate(selectedItem);
            tick();

            expect(timeService.canPostedEntryBeEdited).toHaveBeenCalledWith(1, 9);
            expect(modalService.openModal).toHaveBeenCalled();
            expect(modalService.openModal.mock.calls[0][0]).toEqual(ChangeEntryDateComponent);

            expect(modalService.openModal.mock.calls[0][1].initialState.item).toEqual(selectedItem);
            expect(modalService.openModal.mock.calls[0][1].initialState.initialDate).toEqual(c.currentDate);
            expect(modalService.openModal.mock.calls[0][1].initialState.isContinued).toEqual(selectedItem.isLastChild);
            expect(modalService.openModal.mock.calls[0][1].initialState.openPeriods).not.toBeNull();
            modalService.openModal.mock.calls[0][1].initialState.openPeriods.subscribe(() => {
                expect(timeService.getOpenPeriods).toHaveBeenCalled();
            });
        }));

        it('for posted items, displays error if server returns error', () => {
            timeService.canPostedEntryBeEdited = jest.fn().mockReturnValue(of(WipStatusEnum.Editable));
            timeService.updateDate = jest.fn().mockReturnValue(of({ error: { alertID: 'ABCD' } }));
            modalService.openModal = jest.fn().mockReturnValue({ content: { saveClicked: of(new Date(2010, 11, 11)) } });

            const selectedItem = new TimeEntryEx({ caseKey: 1234, caseReference: '1234-abc-xyz', isLastChild: true, isPosted: true, entryNo: 1, staffId: 9 });
            c.currentDate = new Date(2000, 10, 10);
            c.changeEntryDate(selectedItem);

            expect(timeService.updateDate).toHaveBeenCalled();
            expect(notificationServiceMock.openAlertModal).toHaveBeenCalled();
        });
    });

    describe('Add on Save', () => {
        it('should not add on if an entry is edited', () => {
            const boundData = {
                data: [
                    {
                        caseKey: -1,
                        entryNo: 11,
                        isUpdated: false
                    }
                ]
            };
            const kendoSpy = timeGridHelper.kendoAddOnSave = jest.fn();
            c.ngOnInit();
            c.timeRecordingSettings.addEntryOnSave = true;
            c.updateTime(new TimeEntryEx());
            c.gridOptions.navigateByIndex = jest.fn();
            c.gridOptions._closeEditMode = jest.fn();
            c.gridOptions.onDataBound(boundData);
            expect(kendoSpy).not.toHaveBeenCalled();
        });
        it('should add on save when the setting is on and vice versa', () => {
            const boundData = [
                {
                    caseKey: -1,
                    entryNo: 11,
                    isUpdated: false
                },
                {
                    caseKey: -2,
                    entryNo: 12,
                    isUpdated: false
                },
                {
                    caseKey: -3,
                    entryNo: 13,
                    isUpdated: true
                },
                {
                    caseKey: -4,
                    entryNo: 14,
                    isUpdated: false
                },
                {
                    caseKey: -5,
                    entryNo: 15,
                    isUpdated: false
                }
            ];
            const kendoSpy = timeGridHelper.kendoAddOnSave = jest.fn();
            c.ngOnInit();
            c.timeRecordingSettings.addEntryOnSave = true;
            c.saveTime();
            c.gridOptions.navigateByIndex = jest.fn();
            c.gridOptions._closeEditMode = jest.fn();
            c.gridOptions.onDataBound(boundData);
            expect(kendoSpy).toHaveBeenCalled();
        });
    });

    describe('Continued Entries', () => {
        const settings: TimeRecordingSettings = {
            displaySeconds: true,
            timeEmptyForNewEntries: true,
            restrictOnWip: true,
            addEntryOnSave: true,
            localCurrencyCode: 'xyz',
            timeFormat12Hours: true,
            hideContinuedEntries: true,
            continueFromCurrentTime: true,
            unitsPerHour: 10,
            roundUpUnits: true,
            considerSecsInUnitsCalc: true,
            enableUnitsForContinuedTime: true,
            valueTimeOnEntry: true,
            canAdjustValues: true,
            canFunctionAsOtherStaff: true,
            wipSplitMultiDebtor: false
        };
        beforeEach(() => {
            timeService.timeList = [
                {
                    caseKey: -457,
                    entryNo: 1,
                    isContinuedGroup: false
                },
                {
                    caseKey: -458,
                    entryNo: 2,
                    isContinuedGroup: false
                },
                {
                    caseKey: -459,
                    entryNo: 3,
                    isContinuedGroup: false,
                    childEntryNo: 6
                },
                {
                    caseKey: -557,
                    entryNo: 4,
                    parentEntryNo: 3,
                    isContinuedGroup: false,
                    childEntryNo: 6
                },
                {
                    caseKey: -558,
                    entryNo: 5,
                    parentEntryNo: 4,
                    isContinuedGroup: false,
                    childEntryNo: 6
                },
                {
                    caseKey: -555,
                    entryNo: 6,
                    parentEntryNo: 5,
                    isContinuedGroup: false
                },
                {
                    caseKey: -555,
                    entryNo: 7,
                    isContinuedGroup: false
                },
                {
                    caseKey: -555,
                    entryNo: 8,
                    parentEntryNo: 7,
                    isContinuedGroup: false
                },
                {
                    caseKey: -555,
                    entryNo: 9,
                    parentEntryNo: 8,
                    isContinuedGroup: false
                },
                {
                    caseKey: -556,
                    entryNo: 10,
                    isContinuedGroup: false
                }];
        });

        it('should call the appropriate methods, to add to the continued group on row click, if they are continued entries', () => {
            const markEntriesInChainSpy = c._markEntriesInChain = jest.fn();

            c.dataItemClicked(new TimeEntryEx({ caseKey: 1, isLastChild: null, isContinuedParent: null }));
            expect(markEntriesInChainSpy).not.toHaveBeenCalled();

            c.dataItemClicked(new TimeEntryEx({ caseKey: 1, isContinuedParent: true }));
            expect(markEntriesInChainSpy).toHaveBeenCalled();

            c.dataItemClicked(new TimeEntryEx({ caseKey: 1, isLastChild: true }));
            expect(markEntriesInChainSpy).toHaveBeenCalled();

            c.dataItemClicked(new TimeEntryEx({ nameKey: 112, isLastChild: true, rowId: 1 }));
            expect(timeService.rowSelectedForKot.next).toHaveBeenCalledWith({ id: '112', type: KotViewForEnum.Name });
        });

        it('should mark all parent entries in chain, if child entry is clicked', () => {
            c._markEntriesInChain(6, null);
            expect(timeService.timeList.find(x => x.entryNo === 5).isContinuedGroup).toBe(true);
            expect(timeService.timeList.find(x => x.entryNo === 4).isContinuedGroup).toBe(true);
            expect(timeService.timeList.find(x => x.entryNo === 3).isContinuedGroup).toBe(true);
        });

        it('should mark all parent entries in chain and the child, if any of the parent entry is clicked', () => {
            c._markEntriesInChain(4, 6);
            expect(timeService.timeList.find(x => x.entryNo === 6).isContinuedGroup).toBe(true);
            expect(timeService.timeList.find(x => x.entryNo === 5).isContinuedGroup).toBe(true);
            expect(timeService.timeList.find(x => x.entryNo === 4).isContinuedGroup).toBe(true);
            expect(timeService.timeList.find(x => x.entryNo === 3).isContinuedGroup).toBe(true);
        });

        it('should call search & collapseAll, only on toggle of the hide continued entries', () => {
            c.ngOnInit();
            const collapseAllSpy = c._grid.collapseAll = jest.fn();
            const gridsettings = [{ id: 18, booleanValue: true, name: 'Hide continued entries', description: 'Parent rows of continued time entries are not shown', isDefault: false }, { id: 19, booleanValue: false, name: 'Show seconds', description: 'Show seconds in time items.', isDefault: false }];
            c.refreshGridForContinuedEntries(gridsettings);
            expect(c._grid.search).toHaveBeenCalled();
            expect(collapseAllSpy).toHaveBeenCalled();
        });
        it('should not call search/collapseAll if hide continued entries is not changed', () => {
            c.ngOnInit();
            const collapseAllSpy = c._grid.collapseAll = jest.fn();
            const gridsettings = [{ id: 18, booleanValue: false, name: 'Hide continued entries', description: 'Parent rows of continued time entries are not shown', isDefault: false }, { id: 19, booleanValue: false, name: 'Show seconds', description: 'Show seconds in time items.', isDefault: false }];
            c.refreshGridForContinuedEntries(gridsettings);
            expect(c._grid.search).not.toHaveBeenCalled();
            expect(collapseAllSpy).not.toHaveBeenCalled();
        });
        it('should return appropriate row class', () => {
            c.ngOnInit();
            c.timeRecordingSettings = settings;
            let rowClass = c.gridOptions.customRowClass({ dataItem: { isContinuedParent: true, isLastChild: false } } as any);
            expect(rowClass).toBe('hide-row');
            c.timeRecordingSettings.hideContinuedEntries = false;
            rowClass = c.gridOptions.customRowClass({ dataItem: { isContinuedParent: true, childEntryNo: 8 } } as any);
            expect(rowClass).toBe(' continued');
            rowClass = c.gridOptions.customRowClass({ dataItem: { isIncomplete: true } } as any);
            expect(rowClass).toBe(' error');
            rowClass = c.gridOptions.customRowClass({ dataItem: { isUpdated: true } } as any);
            expect(rowClass).toBe(' saved');
            rowClass = c.gridOptions.customRowClass({ dataItem: { isContinuedGroup: true } } as any);
            expect(rowClass).toBe(' continued-group');
            rowClass = c.gridOptions.customRowClass({ dataItem: { isPosted: true } } as any);
            expect(rowClass).toBe(' posted');
            rowClass = c.gridOptions.customRowClass({ dataItem: { isLastChild: true } } as any);
            expect(rowClass).toBe(' continued continued-last');
            c.entryInEdit = 10;
            timeForms.hasPendingChanges = true;
            rowClass = c.gridOptions.customRowClass({ dataItem: { entryNo: 10 } } as any);
            expect(rowClass).toBe(' edited');
        });
        it('should set the startTime based on continueFromCurrTime preference', () => {
            c.ngOnInit();
            c._grid = { taskMenuDataItem: { finish: new Date(2020, 1, 1) } } as any;
            c._grid.onAdd = c._grid.editRowAndDetails = jest.fn();
            c.gridOptions.navigateByIndex = jest.fn();
            c.continueTime(new TimeEntryEx());
            expect(timeForms.continue).toHaveBeenCalled();
        });

        describe('Get Continued List', () => {
            it('should return stored list where available', () => {
                c._getParentEntry = jest.fn();
                const list = c.getContinuedList({ continuedChain: [1, 2, 3] });
                expect(list).toEqual([1, 2, 3]);
                expect(c._getParentEntry).not.toHaveBeenCalled();
            });
            it('should get all ancestors of selected item', () => {
                const list = c.getContinuedList({
                    entryNo: 6,
                    parentEntryNo: 5
                });
                expect(_.pluck(list, 'entryNo')).toEqual([6, 5, 4, 3]);
            });
        });

        describe('Continue Time', () => {
            it('should set the new child with the parent entry no', () => {
                const dataItem = new TimeEntryEx({
                    caseKey: 13,
                    nameKey: 10048,
                    start: '2020-01-09T10:48:00',
                    finish: '2020-01-09T11:48:00',
                    elapsedTimeInSeconds: 3600,
                    name: 'Balloon Blast Ball Pty Ltd',
                    caseReference: '000315-1',
                    activity: 'Out of office',
                    localValue: 93.14,
                    foreignValue: 100,
                    foreignCurrency: 'USD',
                    narrativeText: null,
                    notes: 'notes111',
                    staffId: -487,
                    chargeOutRate: 100,
                    localDiscount: null,
                    foreignDiscount: null,
                    totalUnits: 10,
                    isPosted: false,
                    isIncomplete: false,
                    entryNo: 671,
                    parentEntryNo: null,
                    narrativeNo: null,
                    narrativeTitle: null,
                    narrativeCode: null,
                    activityKey: 'OUT',
                    secondsCarriedForward: 100,
                    localCurrencyCode: 'AUD',
                    rowId: 0,
                    isUpdated: false,
                    isContinuedGroup: false
                });
                c.ngOnInit();
                c._grid.onAdd = jest.fn();
                c._grid.editRowAndDetails = jest.fn();
                c.gridOptions.enableGridAdd = true;
                c.gridOptions.navigateByIndex = jest.fn();
                timeContinuationService.continue = jest.fn();
                c.continueTime(dataItem);
                expect(c.newChildEntry.entryNo).toBeNull();
                expect(c.newChildEntry.parentEntryNo).toBe(dataItem.entryNo);
                expect(timeForms.continue).toHaveBeenCalled();
                expect(c.newChildEntry.timeCarriedForward).not.toBeNull();
            });
            it('should not call continue automatically if it is already in the continued mode', () => {
                const dataItem = new TimeEntryEx();
                c.ngOnInit();
                c._grid.onAdd = jest.fn();
                c._createContinuedEntry = jest.fn();
                timeForms.continue = jest.fn();
                timeForms.isContinuedEntryMode = true;
                notificationServiceMock.openDiscardModal.mockReturnValue({ content: { confirmed$: of(), cancelled$: of() } });
                c._grid.removeRow = jest.fn();
                c.continueTime(dataItem);
                c.modalRef.content.confirmed$.subscribe(() => {
                    expect(c._createContinuedEntry).not.toHaveBeenCalled();
                    expect(c._grid.removeRow).toHaveBeenCalled();
                });
            });

            it('should call discard and set it back to add-mode', () => {
                const dataItem = new TimeEntryEx();
                c.ngOnInit();
                c._grid.onAdd = jest.fn();
                c._grid.closeRow = jest.fn();
                c._grid.removeRow = jest.fn();
                c._createContinuedEntry = jest.fn();
                timeForms.continue = jest.fn();
                timeForms.isContinuedEntryMode = false;
                c.gridOptions.enableGridAdd = false;
                timeForms.hasPendingChanges = true;
                notificationServiceMock.openDiscardModal.mockReturnValue({ content: { confirmed$: of(), cancelled$: of() } });
                c.continueTime(dataItem);
                c.modalRef.content.confirmed$.subscribe(() => {
                    expect(c._createContinuedEntry).not.toHaveBeenCalled();
                    expect(c._grid.removeRow).toHaveBeenCalled();
                    expect(c.gridOptions.enableGridAdd).toBe(true);
                });
            });

            it('should call create continued entry if it is not in add/continued mode', () => {
                const dataItem = new TimeEntryEx();
                c.ngOnInit();
                c._grid.onAdd = jest.fn();
                c._grid.wrapper.expandRow = jest.fn();
                c._grid.editRowAndDetails = jest.fn();
                c.gridOptions.navigateByIndex = jest.fn();
                const createContEntrySpy = spyOn(c, '_createContinuedEntry').and.callThrough();
                const markChildEntriesSpy = spyOn(c, '_markEntriesInChain').and.callThrough();
                timeForms.continue = jest.fn();
                timeForms.isContinuedEntryMode = false;
                c.gridOptions.enableGridAdd = true;
                c.continueTime(dataItem);
                expect(createContEntrySpy).toHaveBeenCalled();
                expect(c.gridOptions.enableGridAdd).toBeFalsy();
                expect(markChildEntriesSpy).toHaveBeenCalled();
            });
        });
    });

    describe('Reset form', () => {
        it('should reset the form states and entry modes', () => {
            c.entryInEdit = 11;
            c.ngOnInit();
            c._grid.closeRow = jest.fn();
            c.resetForm(false);
            expect(timeForms.resetForm).toHaveBeenCalled();
            expect(c.entryInEdit).toBeNull();
            expect(c._grid.closeRow).toHaveBeenCalledWith(false, true);
        });
    });

    describe('Open post modal', () => {
        beforeEach(() => {
            c.ngOnInit();
            c.gridOptions.enableGridAdd = true;
        });
        it('should call the service to open the post modal - for entry', () => {
            c.staffNameId = 100;
            c.postEntry({ entryNo: 10 });
            expect(postDialog.showDialog).toHaveBeenCalledWith({ entryNo: 10, staffNameId: 100 }, null, c.currentDate);
        });

        it('should refresh the grid if post done for entry', fakeAsync(() => {
            postDialog.showDialog = jest.fn().mockReturnValue(of(true));
            c.staffNameId = 100;
            c.postEntry({ entryNo: 10 });

            tick();
            expect(c._grid.search).toHaveBeenCalled();
            expect(c._gridFocus.refocus).toHaveBeenCalled();
        }));

        it('should not refresh the grid if post done for entry but grid is in edit mode', fakeAsync(() => {
            c.gridOptions.enableGridAdd = false;
            postDialog.showDialog = jest.fn().mockReturnValue(of(true));
            c.staffNameId = 100;
            c.postEntry({ entryNo: 10 });

            tick();
            expect(c._grid.search).not.toHaveBeenCalled();
            expect(c._gridFocus.refocus).not.toHaveBeenCalled();
        }));

        it('should call the service to open the post modal - for post button', () => {
            c.openPostModal();
            expect(postDialog.showDialog).toHaveBeenCalled();
        });

        it('should call the service to open the post modal - for post button when can post for all', () => {
            c.canPostForAllStaff = true;
            c.openPostModal();

            expect(postDialog.showDialog).toHaveBeenCalledWith(null, c.canPostForAllStaff, c.currentDate);
        });

        it('should refresh the grid if post done from modal', fakeAsync(() => {
            postDialog.showDialog = jest.fn().mockReturnValue(of(true));
            c.staffNameId = 100;
            c.openPostModal();

            tick();
            expect(c._grid.search).toHaveBeenCalled();
            expect(c._gridFocus.refocus).toHaveBeenCalled();
        }));
    });

    describe('onTimesheetForNameChanged', () => {
        beforeEach(() => {
            timeGridHelper.initializeTaskItems = jest.fn();
        });
        it('sets staffId in component and forms service', fakeAsync(() => {
            c.userInfo.userDetails$ = of({} as any as UserIdAndPermissions, {} as any as UserIdAndPermissions, { staffId: 10, displayName: 'A', permissions: null });
            c.ngOnInit();
            tick();
            expect(c.staffNameId).toBe(10);
            expect(timeForms.staffNameId).toBe(10);

            expect(c._grid.search).not.toHaveBeenCalled();
            expect(timeGridHelper.initializeTaskItems).toHaveBeenCalled();
        }));

        it('sets the recieved permissions for edit, if staffId selected', fakeAsync(() => {
            const permissions = { ...new TimeRecordingPermissions(), canRead: true, canUpdate: true };
            c.userInfo.userDetails$ = of({} as any as UserIdAndPermissions, {} as any as UserIdAndPermissions, { staffId: 10, displayName: 'A', permissions })
                .pipe(delay(100));
            c.ngOnInit();

            tick(100);
            const allowedActions = timeGridHelper.initializeTaskItems.mock.calls[0][1];
            expect(_.contains(allowedActions, 'EDIT_TIME')).toBeTruthy();
            expect(_.contains(allowedActions, 'CHANGE_ENTRY_DATE')).toBeTruthy();
            expect(_.contains(allowedActions, 'CASE_WEBLINKS')).toBeTruthy();
            expect(c.gridOptions.canAdd).toBeFalsy();
            expect(c.gridOptions.enableGridAdd).toBeFalsy();
        }));

        it('sets the recieved permissions for canDelete, if staffId selected', fakeAsync(() => {
            const permissions = { ...new TimeRecordingPermissions(), canRead: true, canDelete: true };
            c.userInfo.userDetails$ = of({} as any as UserIdAndPermissions, {} as any as UserIdAndPermissions, { staffId: 10, displayName: 'A', permissions }).pipe(delay(100));
            c.ngOnInit();
            tick(100);

            const allowedActions = timeGridHelper.initializeTaskItems.mock.calls[0][1];
            expect(_.contains(allowedActions, 'DELETE_TIME')).toBeTruthy();
            expect(_.contains(allowedActions, 'CASE_WEBLINKS')).toBeTruthy();
        }));

        it('sets the recieved permissions for canPost, if staffId selected', fakeAsync(() => {
            const permissions = { ...new TimeRecordingPermissions(), canRead: true, canPost: true };
            c.userInfo.userDetails$ = of({} as any as UserIdAndPermissions, {} as any as UserIdAndPermissions, { staffId: 10, displayName: 'A', permissions }).pipe(delay(100));
            c.ngOnInit();
            tick(100);

            const allowedActions = timeGridHelper.initializeTaskItems.mock.calls[0][1];
            expect(_.contains(allowedActions, 'POST_TIME')).toBeTruthy();
        }));

        it('sets the recieved permissions for canAdjustValue, if staffId selected', fakeAsync(() => {
            const permissions = { ...new TimeRecordingPermissions(), canRead: true, canAdjustValue: true };
            timeSettings.getViewData$ = jest.fn().mockReturnValue(of({} as any as UserIdAndPermissions, {} as any as UserIdAndPermissions, { staffId: 10, displayName: 'A', permissions }));
            c.ngOnInit();

            const allowedActions = timeGridHelper.initializeTaskItems.mock.calls[0][1];
            expect(_.contains(allowedActions, 'ADJUST_VALUES')).toBeTruthy();
        }));

        it('resets all the permissions, if staffId is not selected', fakeAsync(() => {
            c.userInfo.userDetails$ = of({} as any as UserIdAndPermissions, {} as any as UserIdAndPermissions, { staffId: null, displayName: 'A', permissions: null }).pipe(delay(100));
            c.ngOnInit();
            tick(100);

            expect(c.staffNameId).toBeNull();
            expect(timeForms.staffNameId).toBeNull();

            expect(c._grid.clear).toHaveBeenCalled();
            expect(timeGridHelper.initializeTaskItems).toHaveBeenCalled();
        }));
    });

    describe('Open Adjust Value modal', () => {
        beforeEach(() => {
            modalService.openModal = jest.fn(() => {
                return { hide: null, content: { refreshGrid: of({}) }, setClass: null };
            });
        });
        it('should call the service to get the view and open the modal', () => {
            timeForms.staffNameId = null;
            const dataItem = new TimeEntryEx({});
            c.adjustValues(dataItem);
            expect(modalService.openModal).toHaveBeenCalledWith(expect.any(Function),
                {
                    animated: false,
                    ignoreBackdropClick: true,
                    class: '',
                    focus: true,
                    initialState: { item: dataItem, staffNameId: null }
                });
            timeForms.staffNameId = -5552368;
            c.adjustValues(dataItem);
            expect(modalService.openModal).toHaveBeenCalledWith(expect.any(Function),
                {
                    animated: false,
                    ignoreBackdropClick: true,
                    class: '',
                    focus: true,
                    initialState: { item: dataItem, staffNameId: -5552368 }
                });
            dataItem.foreignCurrency = 'XYZ';
            c.adjustValues(dataItem);
            expect(modalService.openModal).toHaveBeenCalledWith(expect.any(Function),
                {
                    animated: false,
                    ignoreBackdropClick: true,
                    class: 'modal-lg',
                    focus: true,
                    initialState: { item: dataItem, staffNameId: -5552368 }
                });
        });

        it('should display error, if multi debtor entry', () => {
            timeForms.staffNameId = null;
            const dataItem = new TimeEntryEx({ debtorSplits: [{}, {}] });
            c.adjustValues(dataItem);

            expect(notificationServiceMock.openAlertModal).toHaveBeenCalledWith(null, 'accounting.time.recording.adjustValueMultiDebtorError');
        });
    });

    describe('Timers', () => {
        beforeEach(() => {
            c.userInfo.userDetails$ = of({ staffId: 10, displayName: 'A', permissions: null });
            timeService.timeList = [];
            c.ngOnInit();
            c.gridOptions.enableGridAdd = true;
            c.gridOptions.navigateByIndex = jest.fn();
            c._grid.editRowAndDetails = jest.fn();
            c._grid.closeRow = jest.fn();
            c._grid.onDataBinding = jest.fn();
        });

        describe('Start timer', () => {
            it('initializes start time and saves to server', () => {
                const newStartTime = new Date();
                timeService.toLocalDate = jest.fn().mockReturnValue(newStartTime);
                timeService.startTimer = jest.fn().mockReturnValue(of({}));

                c.startTimer();

                expect(timeCalcService.getStartTime).toHaveBeenCalled();
                expect(timeService.toLocalDate).toHaveBeenCalled();

                expect(timeService.startTimer).toHaveBeenCalled();
                expect(timeService.startTimer.mock.calls[0][0].startDateTime).toEqual(newStartTime);
            });
            it('server call response id pushed to the list', fakeAsync(() => {
                const newStartTime = new Date();
                timeService.toLocalDate = jest.fn().mockReturnValue(newStartTime);
                c._grid.wrapper.expandRow = jest.fn();

                const returnValue = { startedTimer: new TimeEntryEx({ entryNo: 100 }), stoppedTimer: {} };
                timeService.startTimer = jest.fn().mockReturnValue(of(returnValue));
                c.startTimer();

                tick(100);

                expect(timeService.timeList.length).toEqual(1);
                expect(c.entryInEdit).toEqual(100);
                expect(c._grid.editRowAndDetails).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalledWith('accounting.time.recording.timerStarted');
                expect(c.gridOptions.enableGridAdd).toBeFalsy();
            }));

            it('displays information for the previous stopped timer', fakeAsync(() => {
                timeSettings.timeFormat = 'abcd';

                const newStartTime = new Date();
                timeService.toLocalDate = jest.fn().mockReturnValue(newStartTime);

                const returnValue = { startedTimer: new TimeEntryEx({ entryNo: 100 }), stoppedTimer: { start: '1/1/2010 11:20' } };
                timeService.startTimer = jest.fn().mockReturnValue(of(returnValue));
                c._grid.wrapper.expandRow = jest.fn();
                const formattedTime = '11: 20 PM';
                datepipe.transform = jest.fn().mockReturnValue(formattedTime);

                c.startTimer();

                tick(100);

                expect(timeService.timeList.length).toEqual(1);
                expect(notificationService.success).toHaveBeenCalled();
                expect(notificationService.success.mock.calls[0][0]).toEqual('accounting.time.recording.timerStoppedAndNewStarted');
                expect(notificationService.success.mock.calls[0][1].startTime).toEqual(formattedTime);

                expect(datepipe.transform).toHaveBeenCalled();
                expect(datepipe.transform.mock.calls[0][0]).toEqual('1/1/2010 11:20');
                expect(datepipe.transform.mock.calls[0][1]).toEqual(timeSettings.timeFormat);
            }));

            it('calls to save  data for previous running timer, before new one can be started', () => {
                timeForms.isTimerRunning = true;
                timeForms.getDataToSave = jest.fn().mockReturnValue({ a: 'abcd' });

                const newStartTime = new Date();
                timeService.getTimeEntryFromList = jest.fn().mockReturnValue({});
                timeService.saveTimer = jest.fn().mockReturnValue(of({}));
                timeService.toLocalDate = jest.fn().mockReturnValue(newStartTime);
                timeService.startTimer = jest.fn().mockReturnValue(of({}));

                c.startTimer();

                expect(timeCalcService.getStartTime).toHaveBeenCalled();
                expect(timeService.toLocalDate).toHaveBeenCalled();
                expect(timeService.saveTimer).toHaveBeenCalled();
                expect(timeForms.resetForm).toHaveBeenCalled();

                expect(timeService.startTimer).toHaveBeenCalled();
                expect(timeService.startTimer.mock.calls[0][0].startDateTime).toEqual(newStartTime);
            });
        });

        describe('Stop timer', () => {
            it('should collect data on stopTimer, and call server', () => {
                timeForms.isTimerRunning = true;
                const totalTimeExpected = new Date(1899, 0, 1, 0, 1, 6);
                timeService.saveTimer = jest.fn().mockReturnValue(of({}));
                const formsData = { case: 'somecase' };
                c.entryInEdit = 100;
                const newStartTime = new Date();
                timeService.toLocalDate = jest.fn().mockReturnValueOnce(newStartTime).mockReturnValueOnce(totalTimeExpected);
                timeForms.getDataToSave = jest.fn().mockReturnValue(formsData);
                c._timer = { time: 66 } as any;

                c.stopTimer({ entryNo: 100, start: '1/1/2019', isTimer: true, staffId: 9 } as any);

                expect(timeForms.getDataToSave).toHaveBeenCalled();
                expect(timeService.toLocalDate).toHaveBeenCalledTimes(2);
                expect(timeService.toLocalDate.mock.calls[1][0]).toEqual(totalTimeExpected);

                expect(timeService.saveTimer).toHaveBeenCalled();
                expect(timeService.saveTimer.mock.calls[0][0].start).toEqual(newStartTime);
                expect(timeService.saveTimer.mock.calls[0][0].totalTime).toEqual(totalTimeExpected);
                expect(timeService.saveTimer.mock.calls[0][0].entryNo).toEqual(100);
                expect(timeService.saveTimer.mock.calls[0][0].staffId).toEqual(9);
                expect(timeService.saveTimer.mock.calls[0][0].case).toEqual(formsData.case);
                expect(timeService.saveTimer.mock.calls[0][1]).toBeTruthy();
            });
            it('should call server with non edited details, when stopping timer in view mode', () => {
                const totalTimeExpected = new Date(1899, 0, 1, 0, 1, 6);
                timeService.stopTimer = jest.fn().mockReturnValue(of({}));
                const newStartTime = new Date();
                timeService.toLocalDate = jest.fn().mockReturnValueOnce(newStartTime).mockReturnValueOnce(totalTimeExpected);
                timeForms.getDataToSave = jest.fn().mockReturnValue({});
                c._timer = { time: 66 } as any;

                c.stopTimer({ entryNo: 100, start: '1/1/2019', isTimer: true, staffId: 9 } as any);

                expect(timeForms.getDataToSave).not.toHaveBeenCalled();
                expect(timeService.toLocalDate).toHaveBeenCalledTimes(2);
                expect(timeService.toLocalDate.mock.calls[1][0]).toEqual(totalTimeExpected);

                expect(timeService.stopTimer).toHaveBeenCalled();
                expect(timeService.stopTimer.mock.calls[0][0].start).toEqual(newStartTime);
                expect(timeService.stopTimer.mock.calls[0][0].totalTime).toEqual(totalTimeExpected);
                expect(timeService.stopTimer.mock.calls[0][0].entryNo).toEqual(100);
                expect(timeService.stopTimer.mock.calls[0][0].staffId).toEqual(9);
            });
            it('should display notification and success message after stopTimer', fakeAsync(() => {
                c.initCaseKey = null;
                timeService.stopTimer = jest.fn().mockReturnValue(of(new TimeEntryEx({ entryNo: 100 })));
                const newStartTime = new Date();
                timeService.toLocalDate = jest.fn().mockReturnValue(newStartTime);
                timeService.getTimeEntryFromList = jest.fn().mockReturnValue({ finish: new Date() });
                c._timer = { time: 66 } as any;
                c.stopTimer({ entryNo: 100, start: '1/1/2019', isTimer: true, staffId: 9, finish: new Date() } as any);

                tick(100);
                expect(c.updatedEntryNo).toEqual(100);
                expect(notificationService.success).toHaveBeenCalled();
                expect(c._grid.search).toHaveBeenCalled();
                expect(timeForms.resetForm).toHaveBeenCalled();
                c.gridOptions.onDataBound([{ entryNo: 1, isUpdated: false }, { entryNo: 100, isUpdated: true }]);
                tick(20);
                flush();
                expect(c._gridFocus.setFocusOnMasterRow).toHaveBeenCalledWith(1, 1);
                expect(c._grid.navigateByIndex).toHaveBeenCalledWith(1);
            }));

            it('should display info alert if stopTimer done on earlier day timer', fakeAsync(() => {
                timeSettings.timeFormat = 'abcd';
                timeService.stopTimer = jest.fn().mockReturnValue(of({ response: { entryNo: 100, finish: new Date('1/1/2010 11: 10') } }));
                const newStartTime = new Date();
                timeService.toLocalDate = jest.fn().mockReturnValueOnce(newStartTime);
                datepipe.transform = jest.fn().mockReturnValue('formattedFinish');
                timeService.getTimeEntryFromList = jest.fn().mockReturnValue({ finish: new Date('1/1/2010 11: 10') });
                c._timer = { time: 66 } as any;
                c.stopTimer({ entryNo: 100, start: '1/1/2019', isTimer: true, staffId: 9, finish: new Date() } as any);

                tick(100);
                expect(modalService.openModal).toHaveBeenCalled();
                expect(translateService.instant).toHaveBeenCalledWith('accounting.time.recording.maxTimeTimer', { finishTime: 'formattedFinish' });
            }));
        });

        describe('Resetting timer', () => {
            it('should reset all the timer details where specified', () => {
                const newTime = new Date();
                timeForms.clearTime = jest.fn();
                timeCalcService.getStartTime = jest.fn().mockReturnValue(newTime);
                c._timer = { resetTimer: jest.fn() } as any;
                c.onReset(new TimeEntryEx({ isTimer: true }), true);

                expect(timeForms.clearTime).toHaveBeenCalled();
                expect(timeCalcService.getStartTime).toHaveBeenCalled();
                expect(c._timer.resetTimer).toHaveBeenCalled();
                expect(timeService.resetTimerEntry).toHaveBeenCalled();
            });
            it('should reset only the start time by default', () => {
                const newTime = new Date();
                timeForms.resetForm = jest.fn();
                timeCalcService.getStartTime = jest.fn().mockReturnValue(newTime);
                c._timer = { resetTimer: jest.fn() } as any;
                c.onReset(new TimeEntryEx({ isTimer: true }));

                expect(timeForms.resetForm).not.toHaveBeenCalled();
                expect(timeCalcService.getStartTime).toHaveBeenCalled();
                expect(c._timer.resetTimer).toHaveBeenCalled();
                expect(timeService.resetTimerEntry).toHaveBeenCalled();
            });
        });

        describe('Continuing as timer', () => {
            beforeEach(() => {
                timeService.timeList = [{ entryNo: 123, parentEntryNo: 100 }];
                timeService.startTimer = jest.fn().mockReturnValue(of({}));
                timeService.saveTimer = jest.fn().mockReturnValue(of({}));
                timeCalcService.getStartTime = jest.fn().mockReturnValue(new Date(11, 1, 2010, 10));
            });
            it('saves any running timers', () => {
                timeForms.isTimerRunning = true;
                c.continueTimer(new TimeEntryEx({ finish: new Date(11, 1, 2010, 10) }));
                expect(timeService.saveTimer).toHaveBeenCalled();
                expect(timeService.startTimer).toHaveBeenCalledWith(expect.any(Object), true);
                timeService.startTimer().subscribe(() => {
                    expect(cdRef.detectChanges).toHaveBeenCalled();
                });
            });
            it('cancels continue if unable to add rows', () => {
                c.checkOnCurrentEntryInForm = jest.fn().mockReturnValue(of({}));
                c.gridOptions.enableGridAdd = false;
                c.continueTimer(new TimeEntryEx({}));
                expect(timeService.startTimer).not.toHaveBeenCalled();
            });
            it('starts a timer', () => {
                timeForms.isTimerRunning = false;
                c.checkOnCurrentEntryInForm = jest.fn().mockReturnValue(of({}));
                c.continueTimer(new TimeEntryEx({ finish: new Date(11, 1, 2010, 10) }));
                expect(timeService.saveTimer).not.toHaveBeenCalled();
                expect(timeService.startTimer).toHaveBeenCalledWith(expect.any(Object), true);
                timeService.startTimer().subscribe(() => {
                    expect(cdRef.detectChanges).toHaveBeenCalled();
                });
            });

            it('displays error if finish time of parent is greater than the current time', () => {
                timeForms.isTimerRunning = false;
                c.checkOnCurrentEntryInForm = jest.fn().mockReturnValue(of({}));
                c.continueTimer(new TimeEntryEx({ finish: new Date(11, 1, 2010, 12) }));
                expect(timeService.startTimer).not.toHaveBeenCalledWith(expect.any(Object), true);
            });
        });
    });

    describe('duplicate entry', () => {
        it('displays the duplicate entries dialog', () => {
            modalService.content = { requestRaised: of(true) };
            c.duplicateEntry(new TimeEntryEx({ entryNo: 10 }));

            expect(modalService.openModal).toHaveBeenCalledWith(DuplicateEntryComponent, { focus: true, initialState: { entryNo: 10 } });
        });

        it('displays success message with count on completion', () => {
            modalService.content = { requestRaised: of(true) };
            c.duplicateEntry(new TimeEntryEx({ entryNo: 10 }));

            expect(notificationService.success).toHaveBeenCalled();
            expect(notificationService.success.mock.calls[0][1]).toEqual({ count: 10 });
        });

        it('displays no records created message, if no records created on completion', () => {
            modalService.content = { requestRaised: of(true) };
            duplicateService.requestDuplicateOb$ = of(0);

            c.duplicateEntry(new TimeEntryEx({ entryNo: 10 }));

            expect(notificationService.success).toHaveBeenCalledWith('accounting.time.duplicateEntry.requestCompletedNoRecord');
        });

        it('displays request raised message, if request takes longer to complete', fakeAsync(() => {
            modalService.content = { requestRaised: of(true) };
            duplicateService.requestDuplicateOb$ = of(9).pipe(delay(5000));

            c.duplicateEntry(new TimeEntryEx({ entryNo: 10 }));

            tick(3000);
            expect(notificationService.success).toHaveBeenCalledWith('accounting.time.duplicateEntry.requestRaised');

            tick(2000);
            expect(notificationService.success).toHaveBeenCalledWith('accounting.time.duplicateEntry.requestCompleted', { count: 9 });
        }));
    });

    describe('case narrative', () => {
        it('displays the maintain case narratives dialog', () => {
            modalService.content = { onClose$: of(true) };
            c.maintainCaseBillNarrative(new TimeEntryEx({ caseKey: 10 }));

            expect(modalService.openModal).toHaveBeenCalledWith(CaseBillNarrativeComponent, {
                focus: true,
                animated: false,
                backdrop: 'static',
                class: 'modal-lg',
                initialState: { caseKey: 10 }
            });
        });

        it('displays success message with count on completion', () => {
            modalService.content = { onClose$: of(true) };
            c.maintainCaseBillNarrative(new TimeEntryEx({ caseKey: 10 }));

            expect(notificationService.success).toHaveBeenCalled();
        });
    });

    describe('helper functions', () => {
        it('calculates the accumilated duration', () => {
            const result = c.getAggregateDuration(new Date(1899, 1, 1, 10, 10, 1), 3600);
            expect(result).toEqual(40201);
        });
    });

    describe('shortcuts', () => {
        it('calls to initialize shortcut keys on init', () => {
            c.ngOnInit();
            expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.SAVE, RegisterableShortcuts.ADD, RegisterableShortcuts.REVERT, RegisterableShortcuts.EDIT]);
        });

        it('does nothing if key not sent or not found in callbacks map', fakeAsync(() => {
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SEARCH;

            const saveSpy = jest.spyOn(c, 'onSave');
            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(saveSpy).not.toHaveBeenCalled();
        }));

        it('calls correct function on add', fakeAsync(() => {
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.ADD;

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(c._grid.onAdd).toHaveBeenCalled();
        }));

        it('does not call function on save, if form invalid', fakeAsync(() => {
            timeForms.isFormValid = false;
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
            const saveSpy = jest.spyOn(c, 'onSave');

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(saveSpy).not.toHaveBeenCalled();
        }));

        it('does not call function on save, if form has no changes', fakeAsync(() => {
            timeForms.isFormValid = true;
            timeForms.hasPendingChanges = false;
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
            const saveSpy = jest.spyOn(c, 'onSave');

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(saveSpy).not.toHaveBeenCalled();
        }));

        it('calls function on save, if form is valid and has changes', fakeAsync(() => {
            timeForms.isFormValid = true;
            timeForms.hasPendingChanges = true;
            c.hasAddedRow = true;
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
            const saveSpy = jest.spyOn(c, 'onSave');

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(saveSpy).toHaveBeenCalled();
        }));

        it('calls timer function on save, if form is valid and has changes for timer', fakeAsync(() => {
            timeForms.isFormValid = true;
            timeForms.hasPendingChanges = true;
            c.entryInEdit = 100;
            timeService.getTimeEntryFromList = jest.fn().mockReturnValue({ isTimer: true });
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
            const updateTimerSpy = jest.spyOn(c, 'updateTimer');

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(updateTimerSpy).toHaveBeenCalled();
        }));

        it('calls cancelEdit function on revert', fakeAsync(() => {
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
            c.entryInEdit = 100;
            timeService.getTimeEntryFromList = jest.fn().mockReturnValue({});
            // tslint:disable-next-line: no-unbound-method
            const cancelEditSpy = jest.spyOn(c, 'cancelEdit').mockImplementation(() => angular.noop);

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(cancelEditSpy).toHaveBeenCalled();
        }));

        it('calls cancelcontinued function on revert', fakeAsync(() => {
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
            timeForms.isContinuedEntryMode = true;
            const cancelContinuedSpy = jest.spyOn(c, 'cancelContinued');

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(cancelContinuedSpy).toHaveBeenCalled();
        }));

        it('calls onReset function on revert', fakeAsync(() => {
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
            const onResetSpy = jest.spyOn(c, 'onReset');

            c.ngOnInit();
            tick(shortcutsService.interval);
            expect(onResetSpy).toHaveBeenCalled();
        }));
    });

    describe('editing posted multidebtor entries is restricted', () => {
        it('displays error on trying to change date of posted multi debtor entry', () => {
            c.ngOnInit();
            const selectedItem = new TimeEntryEx({ caseKey: 1234, caseReference: '1234-abc-xyz', isLastChild: true, isPosted: true, debtorSplits: [1, 2] });
            c.currentDate = new Date(2000, 10, 10);
            c.changeEntryDate(selectedItem);

            expect(notificationServiceMock.openAlertModal).toHaveBeenCalledWith(null, 'accounting.time.editPostedTime.multiDebtorError');
            expect(modalService.openModal).not.toHaveBeenCalled();
        });

        it('displays error on trying to delete posted multi debtor entry', () => {
            timeService.canPostedEntryBeEdited = jest.fn().mockReturnValue(of(WipStatusEnum.Billed));
            const dataItem = new TimeEntryEx({
                caseKey: -457,
                isPosted: true,
                debtorSplits: [1, 2]
            });

            c.deleteTime(dataItem);

            expect(notificationServiceMock.openAlertModal).toHaveBeenCalledWith(null, 'accounting.time.editPostedTime.multiDebtorError');
            expect(timeService.canPostedEntryBeEdited).not.toHaveBeenCalled();
        });

        it('displays error on trying to edit posted multi debtor entry', () => {
            c.ngOnInit();
            const editRowSpy = c.gridOptions.editRow = jest.fn();

            const event = { entryNo: 1, isPosted: true, staffId: 9, debtorSplits: [1, 2] };
            c.editTime(event);

            expect(notificationServiceMock.openAlertModal).toHaveBeenCalledWith(null, 'accounting.time.editPostedTime.multiDebtorError');
            expect(timeService.canPostedEntryBeEdited).not.toHaveBeenCalled();
            expect(editRowSpy).not.toHaveBeenCalled();
        });
    });

    describe('case attachments', () => {
        it('initiates call to display the attachments modal', () => {
            timeSettings.getViewData$ = jest.fn().mockReturnValue(of({ canViewCaseAttachments: true }));
            timeGridHelper.initializeTaskItems = jest.fn();

            c.ngOnInit();

            c.viewCaseAttachments({ caseKey: 5 } as unknown as TimeEntryEx);

            expect(attachmentModalService.displayAttachmentModal).toHaveBeenCalled();
            expect(attachmentModalService.displayAttachmentModal.mock.calls[0][0]).toEqual('case');
            expect(attachmentModalService.displayAttachmentModal.mock.calls[0][1]).toEqual(5);
            expect(attachmentModalService.displayAttachmentModal.mock.calls[0][2]).toEqual(null);
        });
    });
});