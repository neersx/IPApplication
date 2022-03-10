import { discardPeriodicTasks, fakeAsync, flush, tick } from '@angular/core/testing';
import { FormBuilder, RequiredValidator } from '@angular/forms';
import { DateHelperMock } from 'ajs-upgraded-providers/mocks/date-helper.mock';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { BehaviorSubjectMock, ChangeDetectorRefMock, IpxNotificationServiceMock, MessageBroker, NgZoneMock, NotificationServiceMock, StateServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { KotViewForEnum } from 'rightbarnav/keep-on-top-notes-view.service';
import { of } from 'rxjs';
import { delay } from 'rxjs/internal/operators/delay';
import { ReportExportFormat } from 'search/results/report-export.format';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { FileDownloadServiceMock } from 'shared/shared-services/file-download.service.mock';
import { TimeEntryEx, TimeRecordingPermissions } from '../time-recording-model';
import { PostTimeDialogServiceMock, TimeRecordingServiceMock, TimeSearchServiceMock, TimeSettingsServiceMock, UserInfoServiceMock } from '../time-recording.mock';
import { TimeRecordingQueryData } from './time-recording-query-model';
import { TimeRecordingQueryComponent } from './time-recording-query.component';

describe('TimeRecordingQueryComponent', () => {
    let component: TimeRecordingQueryComponent;
    let stateService: any;
    let settingsService: any;
    let cdRef: any;
    let searchService: any;
    let appContextService: any;
    let localSettings: any;
    let userInfoService: any;
    let translateService: any;
    let messageBroker: any;
    let searchExportService: any;
    let zone: any;
    let fileDownloadService: any;
    let notificationService: any;
    let behaviorSubjectMock: any;
    let timeRecordingService: any;
    let postTimeService: any;
    let modalService: any;
    let ipxNotificationService: any;
    let hasSearchBeenRunNextSpy: any;
    let postDialog: any;
    let dateHelper: any;
    let warningCheckerService: any;
    const entryDate = new Date(2000, 1, 1);
    beforeEach(() => {
        stateService = new StateServiceMock();
        stateService.params = {
            entryDate
        };
        settingsService = new TimeSettingsServiceMock();
        cdRef = new ChangeDetectorRefMock();
        searchService = new TimeSearchServiceMock();
        appContextService = new AppContextServiceMock();
        localSettings = new LocalSettingsMock();
        userInfoService = new UserInfoServiceMock();
        translateService = new TranslateServiceMock();
        messageBroker = new MessageBroker();
        searchExportService = {
            export: jest.fn(),
            generateContentId: jest.fn().mockImplementation(jest.fn().mockReturnValue(of(777))),
            removeAllContents: jest.fn().mockReturnValue(of([]))
        };
        zone = new NgZoneMock();
        fileDownloadService = new FileDownloadServiceMock();
        notificationService = new NotificationServiceMock();
        behaviorSubjectMock = new BehaviorSubjectMock();
        timeRecordingService = new TimeRecordingServiceMock();
        postTimeService = {
            getView: jest.fn().mockImplementation(jest.fn().mockReturnValue(of({})))
        };
        modalService = new ModalServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        postDialog = new PostTimeDialogServiceMock();
        dateHelper = new DateHelperMock();
        warningCheckerService = { performCaseWarningsCheck: jest.fn().mockReturnValue(of(true)), performNameWarningsCheck: jest.fn().mockReturnValue(of(true))};
        component = new TimeRecordingQueryComponent(stateService, settingsService, cdRef, searchService, appContextService,
            localSettings, userInfoService, translateService, messageBroker, searchExportService, zone, fileDownloadService, notificationService, timeRecordingService, ipxNotificationService, postDialog, modalService, dateHelper, warningCheckerService);
        component.searchResultsGrid = new IpxKendoGridComponentMock() as any;
        const formBuilder = new FormBuilder();
        component.searchForm = { form: formBuilder.group({ staff: ['', RequiredValidator] } as any) } as any;
        hasSearchBeenRunNextSpy = jest.spyOn(component._hasSearchBeenRun, 'next');
        component._hasRowSelection = new BehaviorSubjectMock() as any;
        component._hasSingleRowSelection = new BehaviorSubjectMock() as any;
    });

    describe('Initialisation', () => {
        it('should create', () => {
            expect(component).toBeTruthy();
            expect(component._isNewSearch).toBe(false);
        });

        it('should initialise the form and gridOptions', () => {
            component.ngOnInit();
            expect(component.formData).toEqual(expect.any(TimeRecordingQueryData));
            expect(component.formData.isUnposted).toBe(true);
            expect(component.formData.isPosted).toBe(true);
            expect(component.searchGridOptions).toBeDefined();
            expect(component.searchGridOptions.reorderable).toBeTruthy();
            expect(component.searchGridOptions.columnPicker).toBeTruthy();
            expect(component.searchResultsGrid.rowSelectionChanged.subscribe).toHaveBeenCalledTimes(1);
            expect(component._hasRowSelection.next).toHaveBeenCalledWith(false);
            expect(timeRecordingService.showKeepOnTopNotes).toHaveBeenCalled();
            expect(component.periods.length).toBe(5);
        });
        it('should set the default staff from userInfoService if available', done => {
            component.ngOnInit();
            userInfoService.userDetails$.subscribe((user: any) => {
                expect(component.defaultStaffName).toBe('Some Man');
                expect(component.defaultStaffNameId).toBe(1);
                expect(timeRecordingService.getUserPermissions).toHaveBeenCalled();
                expect(userInfoService.setUserDetails).toHaveBeenCalledWith(user);

                timeRecordingService.getUserPermissions().subscribe(() => {
                    expect(component.onPermissionsRecieved).toHaveBeenCalled();
                    done();
                });
            });
            expect(component.isFromTimeRecording).toBeTruthy();
            appContextService.appContext$.subscribe(() => {
                expect(component.showWebLinks).toBe(true);
                done();
            });
        });
        it('should request for filter search data', done => {
            component.ngOnInit();
            expect(searchService.searchParamData$).toHaveBeenCalled();
            searchService.searchParamData$().subscribe((response: any) => {
                expect(component.searchParams).toBeDefined();
                expect(response.settings.displaySeconds).toBeTruthy();
                done();
                expect(component.displaySeconds).toBeTruthy();
            });
        });
        it('should enable all bulk-actions', () => {
            component.ngOnInit();
            expect(component.bulkActions).toBeDefined();
            expect(hasSearchBeenRunNextSpy).toHaveBeenCalledWith(false);
        });
        it('should process Downloadable Contents', () => {
            const content = [{ contentId: 1, status: 'ready.to.download' }];
            component.dwlContentId$ = behaviorSubjectMock;
            component.bgContentId$ = behaviorSubjectMock;
            spyOn(component.dwlContentId$, 'next');

            component.processContents(content);
            expect(component.dwlContentId$.next).toHaveBeenCalledWith(1);
        });

        it('should process background Contents', () => {
            const content = [{ contentId: 5, status: 'processed.in.background' }];
            component.dwlContentId$ = behaviorSubjectMock;
            component.bgContentId$ = behaviorSubjectMock;
            spyOn(component.bgContentId$, 'next');

            component.processContents(content);
            expect(component.bgContentId$.next).toHaveBeenCalledWith(5);
        });
    });
    describe('When Time Search is not from Time Recording', () => {
        const standaloneState = new StateServiceMock();
        let standaloneComponent: TimeRecordingQueryComponent;
        beforeEach(() => {
            standaloneComponent = new TimeRecordingQueryComponent(standaloneState as any, settingsService, cdRef, searchService, appContextService, localSettings, userInfoService, translateService, messageBroker, searchExportService, zone, fileDownloadService, notificationService, timeRecordingService, ipxNotificationService, postTimeService, modalService, dateHelper, warningCheckerService);
            standaloneComponent.searchResultsGrid = new IpxKendoGridComponentMock() as any;
        });
        it('should disable Close button and default the staff', () => {
            timeRecordingService.getUserPermissions = jest.fn().mockReturnValue(of(new TimeRecordingPermissions({ canPost: true, canDelete: false })));
            standaloneComponent.ngOnInit();
            expect(standaloneComponent.formData).toBeDefined();
            expect(standaloneComponent.isFromTimeRecording).toBeFalsy();
            expect(searchService.searchParamData$).toHaveBeenCalled();

            expect(standaloneComponent.searchParams).toBeDefined();
            expect(standaloneComponent.displaySeconds).toBeTruthy();
            expect(standaloneComponent.defaultStaffNameId).toBe(9876);
            expect(standaloneComponent.defaultStaffName).toBe('xyz, abcd');
            expect(standaloneComponent.formData.staff).toEqual({ displayName: 'xyz, abcd', key: 9876 });

            expect(userInfoService.setUserDetails).toHaveBeenCalled();
            expect(userInfoService.setUserDetails.mock.calls[0][0].permissions.canPost).toBeTruthy();
            expect(userInfoService.setUserDetails.mock.calls[0][0].permissions.canDelete).toBeFalsy();
        });
        it('copying navigates to the current date in time recording', (done) => {
            const entry = {
                ...new TimeEntryEx(),
                ...{
                    caseKey: 1234,
                    start: new Date(),
                    finish: new Date(),
                    totalTime: new Date(),
                    totalUnits: 10,
                    accumulatedTimeInSeconds: 100,
                    elapsedTimeInSeconds: 100,
                    hasDifferentCurrencies: false,
                    hasDifferentChargeRates: false
                }
            };
            standaloneComponent.ngOnInit();
            standaloneComponent._singleEntrySelected = entry;
            standaloneComponent.copyEntry();
            expect(warningCheckerService.performCaseWarningsCheck.mock.calls[0][0]).toBe(1234);
            warningCheckerService.performCaseWarningsCheck(1234).subscribe(() => {
                expect(standaloneState.go).toHaveBeenCalled();
                expect(standaloneState.go.mock.calls[0][0]).toBe('timeRecording');
                const param = standaloneState.go.mock.calls[0][1];
                expect(param.entryDate.toISOString().slice(0, 10)).toEqual((new Date()).toISOString().slice(0, 10));
                done();
            });
        });
    });

    describe('Toggling Posted/Unposted', () => {
        it('sets Posted when Unposted is unchecked', () => {
            component.ngOnInit();
            expect(component.formData.isUnposted).toBe(true);
            expect(component.formData.isPosted).toBe(true);

            component.formData.isUnposted = false;
            component.togglePostedOptions('isUnposted');
            expect(component.formData.isUnposted).toBe(false);
            expect(component.formData.isPosted).toBe(true);
        });
        it('sets Unposted when Posted is unchecked', () => {
            component.ngOnInit();
            component.formData.isUnposted = false;
            component.formData.isPosted = true;

            component.formData.isPosted = false;
            component.togglePostedOptions('isPosted');
            expect(component.formData.isUnposted).toBe(true);
            expect(component.formData.isPosted).toBe(false);
        });
    });

    describe('Toggling Acting as Debtor/Instructor', () => {
        it('sets AsDebtor when AsInstructor is unchecked', () => {
            component.ngOnInit();
            expect(component.formData.asDebtor).toBe(false);
            expect(component.formData.asInstructor).toBe(false);

            component.formData.asInstructor = false;
            component.toggleNameOptions('asInstructor');
            expect(component.formData.asInstructor).toBe(false);
            expect(component.formData.asDebtor).toBe(true);
        });
        it('sets AsInstructor when AsDebtor is unchecked', () => {
            component.ngOnInit();
            component.formData.asInstructor = false;
            component.formData.asDebtor = true;

            component.formData.asDebtor = false;
            component.toggleNameOptions('asDebtor');
            expect(component.formData.asInstructor).toBe(true);
            expect(component.formData.asDebtor).toBe(false);
        });
    });

    describe('On Filters Changed', () => {
        it('defaults Posted option when Entity is set', () => {
            component.ngOnInit();
            component.onEntityChanged(null);
            expect(component.formData.isPosted).toBe(true);
            expect(component.formData.isUnposted).toBe(true);

            component.onEntityChanged({ key: 'abc' });
            expect(component.formData.isPosted).toBe(true);
            expect(component.formData.isUnposted).toBe(false);
        });
        it('defaults Acting As options when Name is set', () => {
            component.ngOnInit();
            component.onNameChanged(null);
            expect(component.formData.asDebtor).toBe(false);
            expect(component.formData.asInstructor).toBe(false);

            component.onNameChanged({ id: '123-abc' });
            expect(component.formData.asDebtor).toBe(true);
            expect(component.formData.asInstructor).toBe(true);
        });

        it('calls detect changes if validity of form changes', fakeAsync(() => {
            component.ngOnInit();
            component.ngAfterViewInit();
            component.searchForm.form.controls.staff.setValue(null);
            component.searchForm.form.controls.staff.setValue('ABCD');
            expect(cdRef.detectChanges).toHaveBeenCalledTimes(2);
            flush();
            discardPeriodicTasks();
        }));
    });

    describe('Close', () => {
        it('goes to previous in history', () => {
            global.history.go = jest.fn();
            component.close();
            expect(stateService.go.mock.calls[0][0]).toBe('timeRecording');
            expect(stateService.go.mock.calls[0][1]).toEqual(expect.objectContaining({ entryDate }));
        });
    });

    describe('search', () => {
        it('calls clears filters and calls search', () => {
            component.ngOnInit();
            component.search(true);
            expect(component.searchResultsGrid.clearFilters).toHaveBeenCalled();
            expect(component.searchResultsGrid.search).toHaveBeenCalled();
            expect(hasSearchBeenRunNextSpy).toHaveBeenCalledWith(true);
            expect(component._hasRowSelection.next).toHaveBeenCalledWith(false);
            expect(component._isNewSearch).toBe(true);

        });
        it('sets the staff and permissions', done => {
            component.ngOnInit();
            component.formData.staff = { id: 1234, displayName: 'Dirk Pitt' };
            component.search();
            expect(component.postingStaff).toBe(component.formData.staff);
            userInfoService.userDetails$.subscribe(() => {
                expect(component._userPermissions.canPost).toBeTruthy();
                done();
            });
        });

        it('does not clearFilters, if clearFilters set to false', () => {
            component.ngOnInit();
            component.search();
            expect(component.searchResultsGrid.clearFilters).not.toHaveBeenCalled();
            expect(component.searchResultsGrid.search).toHaveBeenCalled();
        });
    });

    describe('clear', () => {
        it('resets status to not run', () => {
            component.ngOnInit();
            component.search();
            expect(hasSearchBeenRunNextSpy).toHaveBeenCalledWith(true);
            component.clear();
            expect(component.searchResultsGrid.clearFilters).toHaveBeenCalled();
            expect(component.searchResultsGrid.search).toHaveBeenCalled();
            expect(hasSearchBeenRunNextSpy).toHaveBeenCalledWith(false);
            expect(component._hasRowSelection.next).toHaveBeenCalledWith(false);
            expect(component._isNewSearch).toBe(true);
            expect(timeRecordingService.rowSelectedInTimeSearch.next).toHaveBeenCalledWith(null);
        });
    });

    describe('on row click', () => {
        it('should show kot details on row change', () => {
            let event = {
                caseKey: 123,
                nameKey: 890
            };
            component.dataItemClicked(event);
            expect(timeRecordingService.rowSelectedInTimeSearch.next).toHaveBeenCalledWith({ id: 123, type: KotViewForEnum.Case });
            event = { caseKey: null, nameKey: 890 };
            component.dataItemClicked(event);
            expect(timeRecordingService.rowSelectedInTimeSearch.next).toHaveBeenCalledWith({ id: 890, type: KotViewForEnum.Name });
        });
    });

    describe('navigating to Time Recording', () => {
        it('passes parameters to the state', () => {
            const thisEntryDate = new Date();
            component.ngOnInit();
            component.navigateToTimeRecording(thisEntryDate, 1234);
            expect(stateService.go).toHaveBeenCalled();
            expect(stateService.go.mock.calls[0][1]).toEqual(expect.objectContaining({ entryDate: thisEntryDate }));
        });
    });

    describe('export', () => {
        it('should call the searchExportService', () => {
            component.export(ReportExportFormat.PDF);
            expect(searchExportService.generateContentId).toHaveBeenCalledWith('555');
            expect(messageBroker.getConnectionId).toHaveBeenCalled();
        });
        it('should call the search service to request the export', done => {
            component.export(ReportExportFormat.Excel);
            searchExportService.generateContentId().subscribe((contentId: number) => {
                expect(searchService.exportSearch$).toHaveBeenCalled();
                expect(searchService.exportSearch$.mock.calls[0][2]).toBe('Excel');
                expect(searchService.exportSearch$.mock.calls[0][4]).toBe(777);
                searchService.exportSearch$().subscribe(() => {
                    expect(notificationService.success).toHaveBeenCalled();
                    done();
                });
                done();
            });
        });
    });

    describe('onDestroy', () => {
        it('should disconnect from messageBroker', () => {
            component.bgContentSubscription = { unsubscribe: jest.fn() };
            component.dwnlContentSubscription = { unsubscribe: jest.fn() };

            component.ngOnDestroy();

            expect(messageBroker.disconnectBindings).toHaveBeenCalled();
            expect(component.bgContentSubscription.unsubscribe).toHaveBeenCalled();
            expect(component.dwnlContentSubscription.unsubscribe).toHaveBeenCalled();
        });
    });

    describe('Posting entries', () => {
        it('sends the row selection as entry numbers', () => {
            component.ngOnInit();
            component.postingStaff = { key: 555, displayName: 'DJ Maxx' };
            component.searchResultsGrid.getRowSelectionParams().rowSelection = [1, 2, 3];
            component.postEntries();
            expect(postDialog.showDialog).toHaveBeenCalled();
            expect(postDialog.showDialog.mock.calls[0][0].staffNameId).toBe(555);
            expect(postDialog.showDialog.mock.calls[0][0].entryNumbers).toEqual([1, 2, 3]);
        });
        it('sends the allSelection and deselected as entry numbers', () => {
            component.ngOnInit();
            component.postingStaff = { key: 555, displayName: 'DJ Maxx' };
            component.searchResultsGrid.getRowSelectionParams().isAllPageSelect = true;
            component.searchResultsGrid.getRowSelectionParams().allDeSelectedItems = [{ entryNo: 5 }, { entryNo: 6 }];
            component.postEntries();
            expect(postDialog.showDialog).toHaveBeenCalled();
            expect(postDialog.showDialog.mock.calls[0][0].staffNameId).toBe(555);
            expect(postDialog.showDialog.mock.calls[0][0].isSelectAll).toBeTruthy();
            expect(postDialog.showDialog.mock.calls[0][0].exceptEntryNumbers).toEqual([5, 6]);
        });
    });

    describe('delete', () => {
        beforeEach(() => {
            component.ngOnInit();
            component.postingStaff = { key: 555, displayName: 'DJ Maxx' };

            ipxNotificationService.openDeleteConfirmModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true) } });
            searchService.deleteEntries = jest.fn().mockReturnValueOnce(of(10));
        });
        it('asks for user confirmation for deletion', () => {
            component.deleteEntries();

            expect(ipxNotificationService.openDeleteConfirmModal).toHaveBeenCalledWith('accounting.time.query.deleteConfirmation');
        });

        it('calls service for deletion by passing selected entry numbers', () => {
            component.searchResultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
                isAllPageSelect: false,
                rowSelection: [1, 2, 3]
            });

            component.deleteEntries();

            expect(searchService.deleteEntries).toHaveBeenCalled();
            expect(searchService.deleteEntries.mock.calls[0][0].staffNameId).toEqual(555);
            expect(searchService.deleteEntries.mock.calls[0][0].entryNumbers).toEqual([1, 2, 3]);
        });

        it('calls for deletion by passing search params and excepted entry numbers', () => {
            const searchParams = { a: 'abcd' };
            const queryParams = { b: 'xyz' };
            searchService.getSearchParams = jest.fn().mockReturnValue({ criteria: searchParams, queryParams });
            component.searchResultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
                isAllPageSelect: true,
                allDeSelectedItems: [{ entryNo: 5 }, { entryNo: 6 }]
            });
            component.deleteEntries();
            expect(searchService.getSearchParams).toHaveBeenCalled();
            expect(searchService.deleteEntries).toHaveBeenCalled();

            expect(searchService.deleteEntries.mock.calls[0][0].staffNameId).toEqual(555);
            expect(searchService.deleteEntries.mock.calls[0][0].reverseSelection.exceptEntryNumbers).toEqual([5, 6]);
            expect(searchService.deleteEntries.mock.calls[0][0].reverseSelection.searchParams).toEqual(searchParams);
            expect(searchService.deleteEntries.mock.calls[0][0].reverseSelection.queryParams).toEqual(queryParams);
        });

        it('displays confirmation of deletion', () => {
            component.searchResultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
                isAllPageSelect: false,
                rowSelection: [1, 2, 3]
            });
            component.deleteEntries();
            expect(notificationService.success).toHaveBeenCalledWith('accounting.time.query.deleteSuccess');
        });

        it('refreshes data if another query has not ran after delete request', fakeAsync(() => {
            searchService.deleteEntries = jest.fn().mockReturnValueOnce(of(11).pipe(delay(10))).mockReturnValueOnce(of(10));
            component.searchResultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
                isAllPageSelect: false,
                rowSelection: [1, 2, 3]
            });
            component.deleteEntries();
            component._hasSearchBeenRun.next(true);
            tick(10);
            expect(component.searchResultsGrid.search).not.toHaveBeenCalled();

            component.deleteEntries();
            expect(component.searchResultsGrid.search).toHaveBeenCalled();
        }));
    });

    describe('Update narrative', () => {
        beforeEach(() => {
            component.ngOnInit();
            component.formData.staff = { key: 1234, displayName: 'Dirk Pitt' };
            component.search();
        });
        it('opens an update narrative dialog and pass default data for single non-posted entry selection', () => {
            component.searchResultsGrid.rowSelectionChanged.emit({ rowSelection: [{ isPosted: false, narrativeNo: 10, narrativeText: 'ABCD', caseKey: 555, nameKey: -987 }] });
            component.updateNarrative();

            expect(modalService.openModal).toHaveBeenCalled();
            expect(modalService.openModal.mock.calls[0][1].initialState).toEqual(expect.objectContaining({
                defaultNarrative: {narrativeNo: 10, narrativeText: 'ABCD'},
                defaultNarrativeText: 'ABCD',
                caseKey: 555,
                debtorKey: -987
            }));
        });

        it('opens an update narrative dialog with no default values pased, since single entry selected is posted', () => {
            component.searchResultsGrid.rowSelectionChanged.emit({ rowSelection: [{ isPosted: true, narrativeNo: 10, narrativeText: 'ABCD' }] });
            component.updateNarrative();

            expect(modalService.openModal).toHaveBeenCalled();
            expect(modalService.openModal.mock.calls[0][1].initialState).toEqual({});
        });

        it('opens an update narrative dialog with no default values pased, since multiple entries selected', () => {
            component.searchResultsGrid.rowSelectionChanged.emit({ rowSelection: [{ narrativeNo: 10 }, { narrativeNo: 11 }, { narrativeNo: 12 }] });
            component.updateNarrative();

            expect(modalService.openModal).toHaveBeenCalled();
            expect(modalService.openModal.mock.calls[0][1].initialState).toEqual({});
        });

        it('it calls the service to update narrative after dialog is confirmed', fakeAsync(() => {
            const data = { some: 'data' };
            modalService.content = { confirmed$: of(data).pipe(delay(10)) };

            component.updateNarrative();
            tick(10);
            expect(searchService.updateNarrative).toHaveBeenCalled();
            expect(searchService.updateNarrative.mock.calls[0][0].staffNameId).toEqual(1234);
            expect(searchService.updateNarrative.mock.calls[0][1]).toEqual(data);
        }));

        it('displays success notification dialog after service returns successfully', fakeAsync(() => {
            const data = { some: 'data' };
            modalService.content = { confirmed$: of(data).pipe(delay(10)) };

            component.updateNarrative();
            tick(10);
            expect(searchService.updateNarrative).toHaveBeenCalled();

            expect(notificationService.success).toHaveBeenCalled();
        }));
    });

    describe('Copying an entry', () => {
        it('checks case warnings and navigates to time recording', (done) => {
            const entry = {
                ...new TimeEntryEx(),
                ...{
                    caseKey: 1234,
                    start: new Date(),
                    finish: new Date(),
                    totalTime: new Date(),
                    totalUnits: 10,
                    accumulatedTimeInSeconds: 100,
                    elapsedTimeInSeconds: 100,
                    hasDifferentCurrencies: false,
                    hasDifferentChargeRates: false
                }
            };
            component.ngOnInit();
            component._singleEntrySelected = entry;
            component.copyEntry();
            expect(warningCheckerService.performCaseWarningsCheck.mock.calls[0][0]).toBe(1234);
            warningCheckerService.performCaseWarningsCheck(1234).subscribe(() => {
                expect(stateService.go).toHaveBeenCalled();
                expect(stateService.go.mock.calls[0][0]).toBe('timeRecording');
                expect(stateService.go.mock.calls[0][1]).toEqual(expect.objectContaining({ entryDate }));
                done();
            });
        });
        it('checks name warnings and navigates to time recording', (done) => {
            const entry = {
                ...new TimeEntryEx(),
                ...{
                    name: null,
                    nameKey: 1234,
                    start: new Date(),
                    finish: new Date(),
                    totalTime: new Date(),
                    totalUnits: 10,
                    accumulatedTimeInSeconds: 100,
                    elapsedTimeInSeconds: 100,
                    hasDifferentCurrencies: false,
                    hasDifferentChargeRates: false
                }
            };
            component.ngOnInit();
            component._singleEntrySelected = entry;
            component.copyEntry();
            expect(warningCheckerService.performNameWarningsCheck).toHaveBeenCalledWith(1234, expect.any(Object), expect.any(Date));
            warningCheckerService.performNameWarningsCheck(1234).subscribe(() => {
                expect(stateService.go).toHaveBeenCalled();
                expect(stateService.go.mock.calls[0][0]).toBe('timeRecording');
                expect(stateService.go.mock.calls[0][1]).toEqual(expect.objectContaining({ entryDate }));
                done();
            });
        });
    });

    describe('onChangePeriod', () => {
        beforeEach(() => {
            component.ngOnInit();
        });
        it('defaults nothing when the Date Range option is selected and saves the options', () => {
            component.onChangePeriod(1);

            expect(component.localSettings.keys.accounting.timeSearch.periodSelection.getLocalValue()).toBe(1);
        });
        it('defaults the dates to this week when the This Week option is selected', () => {
            component.onChangePeriod(2);

            expect(component.formData.fromDate.toDateString().includes('Mon')).toBeTruthy();
            expect(component.formData.toDate.toDateString().includes('Sun')).toBeTruthy();
            expect(component.localSettings.keys.accounting.timeSearch.periodSelection.getLocalValue()).toBe(2);
        });
        it('defaults the dates to last week when the Last Week option is selected', () => {
            component.onChangePeriod(4);

            expect(component.formData.fromDate.toDateString().includes('Mon')).toBeTruthy();
            expect(component.formData.toDate.toDateString().includes('Sun')).toBeTruthy();
            expect(component.localSettings.keys.accounting.timeSearch.periodSelection.getLocalValue()).toBe(4);
        });
        it('defaults the dates to this month when the This Month option is selected', () => {
            const today = new Date();
            component.onChangePeriod(3);

            expect(component.formData.fromDate.getDate()).toEqual(1);
            expect(component.formData.toDate.getMonth()).toEqual(today.getMonth());
            expect(component.localSettings.keys.accounting.timeSearch.periodSelection.getLocalValue()).toBe(3);
        });
        it('defaults the dates to last month when the Last Month option is selected', () => {
            const today = new Date();
            const lastMonth = new Date(new Date().setMonth(today.getMonth() - 1));
            component.onChangePeriod(5);

            expect(component.formData.fromDate.getDate()).toEqual(1);
            expect(component.formData.toDate.getMonth()).toEqual(lastMonth.getMonth());
            expect(component.localSettings.keys.accounting.timeSearch.periodSelection.getLocalValue()).toBe(5);
        });
    });
});
