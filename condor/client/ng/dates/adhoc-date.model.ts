export class AdHocDate {
    adHocDateFor: string;
    finaliseReference: string;
    message: string;
    dueDate?: Date;
    dateOccurred?: Date;
    resolveReasons: any;
    alertId: number;
    isBulkUpdate: boolean;
    selectedTaskPlannerRowKeys: Array<string>;
    searchRequestParams: any;
    resolveReason?: string;
    taskPlannerRowKey: string;
}

export class FinaliseRequestModel {
    alertId: number;
    dateOccured?: Date;
    userCode: string;
    taskPlannerRowKey: string;
}

export class BulkFinaliseRequestModel {
    selectedTaskPlannerRowKeys: Array<string>;
    searchRequestParams: any;
    dateOccured?: Date;
    userCode: string;
}

export class AdhocReminder {
    employeeNo: number;
    caseId?: number;
    nameNo?: number;
    reference: string;
    dueDate?: Date;
    alertMessage: string;
    eventNo?: number;
    importanceLevel: string;
    deleteOn?: Date;
    stopReminderDate?: Date;
    isNoReminder: boolean;
    daysLead?: number;
    monthsLead?: number;
    monthlyFrequency?: number;
    dailyFrequency?: number;
    employeeFlag: boolean;
    signatoryFlag: boolean;
    criticalFlag: boolean;
    nameTypeId: string;
    relationship: string;
    sendElectronically: number;
    emailSubject: string;
    dateOccurred?: Date;
    userCode: string;
    taskPlannerRowKey: string;
}