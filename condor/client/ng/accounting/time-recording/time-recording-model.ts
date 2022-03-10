import { NumberValueAccessor } from '@angular/forms';
import { BooleanFilterComponent } from '@progress/kendo-angular-grid';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as _ from 'underscore';

export class TimeEntry {
    start?: Date;
    finish?: Date;
    elapsedTimeInSeconds?: number;
    totalTime?: Date;
    totalUnits?: number;
    name?: '';
    caseReference?: '';
    activity?: string | '';
    chargeOutRate?: number;
    localValue?: number;
    foreignValue?: number;
    localDiscount?: number;
    foreignDiscount?: number;
    narrativeText?: string | '';
    notes?: string | '';
    nameKey?: number;
    caseKey?: number;
    narrativeNo?: Number;
    narrativeCode?: '';
    narrativeTitle?: string | '';
    entryNo?: number;
    parentEntryNo?: number;
    narrativeKey?: number;
    activityKey?: string | '';
    timeCarriedForward?: Date;
    secondsCarriedForward?: number;
    exchangeRate?: number;
    foreignCurrency?: string;
    isTimer?: boolean | false;
    totalDuration?: number;

    entryDate?: Date;
    staffId?: number;
    isPosted?: boolean;
    isIncomplete?: boolean;
    debtorSplits?: Array<DebtorSplit>;

    constructor(data?: any) {
        if (!!data) {
            Object.assign(this, data);
        }
    }

    clearOutTimeSpecifications = (): void => {
        this.start = null;
        this.finish = null;
        this.elapsedTimeInSeconds = 0;
        this.secondsCarriedForward = null;
        this.timeCarriedForward = null;
        this.totalTime = null;
        this.totalUnits = null;
    };
}

export class DebtorSplit {
    entryNo: number;
    debtorNameNo: number;
    splitPercentage: number;
    localValue: number;
    localDiscount: number;
    chargeOutRate: number;
    foreignCurrency: string;
    foreignValue?: number;
    foreignDiscount?: number;
    exchRate?: number;
    narrativeNo?: number;
    narrative: string;
    marginNo?: number;
}

export class TimeEntryEx extends TimeEntry {
    localCurrencyCode?: string;
    isUpdated?: boolean | false;
    childEntryNo?: number = null;
    isContinuedParent?: boolean | false;
    isLastChild?: boolean | false;
    isContinuedGroup?: boolean | false;
    durationOnly?: boolean | false;
    rowId?: number = null;
    overlaps?: boolean | false;

    get accumulatedTimeInSeconds(): number {
        return (!!this.secondsCarriedForward ? this.secondsCarriedForward : 0) + (!!this.elapsedTimeInSeconds ? this.elapsedTimeInSeconds : 0);
    }

    get hasDifferentCurrencies(): boolean {
        return this.debtorSplits && _.uniq(_.pluck(this.debtorSplits, 'foreignCurrency')).length > 1;
    }
    get hasDifferentChargeRates(): boolean {
        return this.debtorSplits && _.uniq(_.pluck(this.debtorSplits, 'chargeOutRate')).length > 1;
    }

    constructor(data?: any) {
        super();
        if (!!data) {
            Object.assign(this, data);
            this.start = !!data.start ? new Date(data.start) : null;
            this.finish = !!data.finish ? new Date(data.finish) : null;
            this.timeCarriedForward = !!data.secondsCarriedForward ? new Date(1899, 0, 1, 0, 0, data.secondsCarriedForward) : null;
            this.entryDate = !!data.entryDate ? new Date(data.entryDate) : null;
            if (this.chargeOutRate === null && (!this.hasDifferentCurrencies && !this.hasDifferentChargeRates)) {
                this.isIncomplete = true;
            }
        }
    }

    makeServerReady = (): TimeEntry => {
        const newTimeEntry = new TimeEntry(this);
        newTimeEntry.activity = newTimeEntry.activityKey;

        if (!!this.elapsedTimeInSeconds) {
            const elapsed = DateFunctions.convertSecondsToTime(Math.abs(this.elapsedTimeInSeconds));
            newTimeEntry.totalTime = DateFunctions.toLocalDate(new Date(1899, 0, 1, elapsed.hours, elapsed.mins, elapsed.secs));
            newTimeEntry.start = DateFunctions.toLocalDate(this.start);
            newTimeEntry.finish = DateFunctions.toLocalDate(this.finish);
        }

        return newTimeEntry;
    };
}
export class TimerEntries {
    startedTimer: TimeEntryEx;
    stoppedTimer: TimeEntryEx;

    constructor(data: any) {
        this.startedTimer = new TimeEntryEx(data.startedTimer);
        this.stoppedTimer = new TimeEntryEx(data.stoppedTimer);
    }
}

export interface Name {
    nameKey: number;
    name: string;
}

export interface PostEntryDetails {
    entryNo?: number;
    entityKey?: number;
    staffNameId?: number;
    entryNumbers?: Array<number>;
    exceptEntryNumbers?: Array<number>;
    isSelectAll?: boolean;
    postingParams?: any;
    canPostForAllStaff?: boolean;
}

export class TimeRecordingSettings {
    displaySeconds: boolean;
    timeEmptyForNewEntries: boolean;
    restrictOnWip: boolean;
    addEntryOnSave: boolean;
    localCurrencyCode: string;
    timeFormat12Hours: boolean;
    hideContinuedEntries: boolean;
    continueFromCurrentTime: boolean;
    unitsPerHour: number;
    roundUpUnits: boolean;
    considerSecsInUnitsCalc: boolean;
    enableUnitsForContinuedTime: boolean;
    wipSplitMultiDebtor: boolean;
    valueTimeOnEntry: boolean;
    canAdjustValues: boolean;
    canFunctionAsOtherStaff: boolean;
    timePickerInterval?: number;
    durationPickerInterval?: number;
}

export class UserTaskSecurity {
    maintainPostedTime: {
        edit: boolean;
        delete: boolean;
    };

    constructor(data?: any) {
        if (!!data) {
            Object.assign(this, data);
        }
    }
}

export class InitialUserInfo {
    nameId: number;
    displayName: string;
    isStaff: boolean;
    canAdjustValues: boolean;
    canFunctionAsOtherStaff: boolean;
    maintainPostedTimeEdit: boolean;
    maintainPostedTimeDelete: boolean;
}

export class DefaultInfo {
    caseId: number;
    caseReference: string;
}

export class EnquiryViewData {
    settings: TimeRecordingSettings;
    canViewCaseAttachments: boolean;
    canPostForAllStaff: boolean;
    userInfo: InitialUserInfo;
    defaultInfo: DefaultInfo;
}

export enum TimeRecordingSettingsEnum {
    SHOW_SECONDS = 19,
    ADD_ON_SAVE = 31,
    TIME_FORMAT_12HOUR = 32,
    HIDE_CONTINUED_ENTRIES = 18,
    CONTINUE_FROM_CURR_TIME = 21,
    VALUE_ON_CHANGE = 33,
    TIME_PICKER_INTERVAL = 39,
    DURATION_PICKER_INTERVAL = 40
}

export class TimeRecordingHeader {
    viewTotals?: TimeRecordingTotals;
}

export class TimeRecordingTotals {
    chargeableSeconds?: number;
    chargeableUnits?: number;
    chargeablePercentage?: number;
    totalHours?: number;
    totalValue?: number;
}

export class EnteredTimes {
    start?: Date;
    finish?: Date;
    elapsedTime?: Date;

    constructor(start: Date, finish: Date, elapsedTime: Date) {
        this.start = start;
        this.finish = finish;
        this.elapsedTime = elapsedTime;
    }

    nullValues(): number {
        return Object.keys(this).filter((item: any) => this[item] === null).length;
    }
}

export class WipWarningData {
    budgetCheckResult?: any;
    caseWipWarnings?: Array<any>;
    prepaymentCheckResult?: any;
    billingCapCheckResult?: Array<any>;
}

export class TimeRecordingPermissions {
    canRead = false;
    canInsert = false;
    canUpdate = false;
    canDelete = false;
    canPost = false;
    canAdjustValue = false;
    canAddTimer = false;

    constructor(data?: any) {
        if (!!data) {
            Object.assign(this, data);
        }
    }
}

export class UserIdAndPermissions {
    staffId: number;
    displayName: string;
    isStaff?: boolean;
    permissions: TimeRecordingPermissions;
}

export class TimeGap {
    id: number;
    startTime: Date;
    finishTime: Date;
    durationInSeconds: number;

    constructor(data: any) {
        Object.assign(this, data);
        this.startTime = new Date(data.startTime);
        this.finishTime = new Date(data.finishTime);
    }

    recalculateDurationInSeconds(): void {
        const duration = new Date(this.finishTime.getTime() - this.startTime.getTime());
        this.durationInSeconds = Math.abs(duration.getTime()) / 1000;
    }
}

export enum WipStatusEnum {
    Editable = 'editable',
    Locked = 'locked',
    Billed = 'billed',
    Adjusted = 'adjusted'
}

export class Period {
    private readonly startDate: Date;
    private readonly endDate: Date;

    constructor(data?: any) {
        this.startDate = DateFunctions.getDateOnly(new Date(data.startDate));
        this.endDate = DateFunctions.getDateOnly(new Date(data.endDate));
    }

    isWithin(date: Date): boolean {
        if (!date) {
            return false;
        }

        const onlyDate = DateFunctions.getDateOnly(date).getTime();

        return onlyDate >= this.startDate.getTime() && onlyDate <= this.endDate.getTime();
    }
}