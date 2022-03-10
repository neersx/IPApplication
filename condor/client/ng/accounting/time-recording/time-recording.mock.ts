import { of } from 'rxjs/internal/observable/of';
import { WipStatusEnum } from './time-recording-model';

export class TimeFieldsMock {
    onStartChange = jest.fn();
    onFinishChange = jest.fn();
    onActivityChanged = jest.fn();
    onElapsedTimeChanged = jest.fn();
    evaluateTime = jest.fn();
    getInputValues = jest.fn();
}

export class TimeCalculationServiceMock {
    calculateElapsed = jest.fn((a) => a);
    calculateFinished = jest.fn();
    calculateStart = jest.fn();
    lockYearMonthDate = jest.fn();
    parsePartiallyEnteredTime = jest.fn().mockImplementation((d) => { return d; });
    parsePartiallyEnteredDuration = jest.fn().mockImplementation((d) => { return d; });
    parseElapsedTime = jest.fn();
    timeFormat = jest.fn();
    initializeStartTime = jest.fn();
    toLocalDate = jest.fn().mockImplementation((d: Date): Date => { return d; });
    getElapsedSeconds = jest.fn();
    calculateElapsedMinMax = jest.fn();
    calculateElapsedMinMaxWithFinishedTime = jest.fn();
    calcDurationFromUnits = jest.fn();
    clearMinMax = jest.fn();
    min = new Date();
    max = new Date(1899, 0, 1, 23, 59, 59);
    selectedDate = new Date();
    getStartTime = jest.fn();
    calcUnitsFromDuration = jest.fn();
    getCurrentTimeFor = jest.fn(d => d);
}

export class TimeContinuationServiceMock {
    continue = jest.fn();
}

export class TimeGridHelperMock {
    getColumnSelectionLocalSetting = jest.fn();
    getColumns = jest.fn().mockReturnValue({});
    initializeTaskItems = jest.fn();
}

export class TimeRecordingServiceMock {
    getUserPermissions = jest.fn().mockReturnValue(of({}));
    getViewData$ = jest.fn().mockReturnValue(of({}));
    getViewTotals = jest.fn();
    rowSelected = { next: jest.fn() };
    rowSelectedForKot = { next: jest.fn() };
    rowSelectedInTimeSearch = { next: jest.fn() };
    saveTimeEntry = jest.fn().mockReturnValue(of({ response: { entyNo: 1 } }));
    getTimeList = jest.fn().mockReturnValue(of({}));
    evaluateTime = jest.fn();
    toLocalDate = jest.fn(d => { return d; });
    getDefaultActivityFromCase = jest.fn();
    getDefaultNarrativeFromActivity = jest.fn().mockReturnValue(of({ narrative: 'a' }));
    recentCases = of({});
    startTimer = jest.fn().mockReturnValue(of({}));
    stopTimer = jest.fn();
    saveTimer = jest.fn().mockReturnValue(of({}));
    updateTimeEntry = jest.fn().mockReturnValue(of({}));
    resetTimerEntry = jest.fn().mockReturnValue(of({}));
    getRowIdFor = jest.fn();
    stopPrevTimer = jest.fn().mockReturnValue(of({}));
    getTimeEntryFromList = jest.fn().mockReturnValue({});
    onRecordUpdated = jest.fn().mockReturnValue(of({}));
    canPostedEntryBeEdited = jest.fn().mockReturnValue(of(WipStatusEnum.Editable));
    getOpenPeriods = jest.fn().mockReturnValue(of({}));
    showKeepOnTopNotes = jest.fn().mockReturnValue(of({}));
}

export class TimeSettingsServiceMock {
    getViewData$ = jest.fn().mockReturnValue(of({ userInfo: { displayName: 'ABC-xyz', nameId: -12345, isStaff: true } }));
    timeFormat = 'hh:mm:ss a';
    displaySecondsOnChange = of({});
    displaySeconds = true;
    userTaskSecurity = {
        maintainPostedTime: {
            edit: true
        }
    };
}

export class TimesheetFormsServiceMock {
    dateChanged = jest.fn();
    isFormValid = true;
    getDataToSave = jest.fn();
    resetForm = jest.fn();
    initializeStartTime = jest.fn();
    continue = jest.fn();
    hasPendingChanges = true;
    getSelectedCaseRef = jest.fn();
    loadFormData = jest.fn();
    evaluateTime = jest.fn();
    getInputValues = jest.fn();
    checkIfActivityCanBeDefaulted = jest.fn();
    defaultFinishTime = jest.fn();
    defaultNarrativeFromActivity = jest.fn().mockReturnValue(of({}));
    createFormGroup = jest.fn();
    clearTime = jest.fn();
}

export class TimeGapsServiceMock {
    getGaps = jest.fn().mockReturnValue(of({}));
    addEntries = jest.fn().mockReturnValue(of({}));
    getWorkingHoursFromServer = jest.fn();
    saveWorkingHours = jest.fn().mockReturnValue(of({}));
    preferenceSaved$ = jest.fn().mockReturnValue(of({}));
}

export class UserInfoServiceMock {
    userDetails$ = of({
        staffId: 1,
        displayName: 'Some Man',
        permissions: {
            canPost: true
        }
    });
    setUserDetails = jest.fn();
}
export class DuplicateEntryServiceMock {
    initiateDuplicationRequest = jest.fn();
    requestDuplicateOb$ = of(10);
}

export class PostTimeDialogServiceMock {
    showDialog = jest.fn().mockReturnValue(of(false));
}

export class TimeSearchServiceMock {
    searchParamDataResult = of({
        settings: { displaySeconds: true },
        userInfo: { displayName: 'xyz, abcd', nameId: 9876 }
    });

    getSearchParamsResult = of({
        data: { key: 1234, value: 2345 }
    });

    recentEntriesResult = of();

    recentEntries$ = jest.fn().mockImplementation(() => this.recentEntriesResult);
    runSearch$ = jest.fn().mockReturnValue(of({}));
    searchParamData$ = jest.fn().mockImplementation(() => this.searchParamDataResult);
    timeSummary$ = of({});
    exportSearch$ = jest.fn().mockReturnValue(of({}));
    getSearchParams = jest.fn().mockImplementation(() => this.getSearchParamsResult);
    deleteEntries = jest.fn().mockReturnValue(of(10));
    updateNarrative = jest.fn().mockReturnValue(of({}));
}