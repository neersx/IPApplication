
export class EventRulesRequest {
    caseId: number;
    eventNo: number;
    cycle: number;
    action: string;
}
export class EventRulesDetailsModel {
    caseReference: string;
    eventDescription: string;
    action: string;
    notes: string;
    eventInformation: EventInformation;
    dueDateCalculationInfo: DueDateCalculationInfo;
    remindersInfo: Array<RemindersInfo>;
    documentsInfo: Array<DocumentsInfo>;
    datesLogicInfo: Array<DatesLogicDetailInfo>;
    eventUpdateInfo: EventUpdateInfo;
}

export class EventInformation {
    eventNumber: number;
    cycle: number;
    eventDate?: Date;
    lastModified?: Date;
    criteriaNumber: number;
    byLogin: string;
    importanceLevel: number;
    from: string;
    maximumCycle: number;
}

export class DueDateCalculationInfo {
    heading: string;
    standingInstructionInfo: string;
    dueDateComparisonInfo: string;
    extensionInfo: string;
    hasRecalculateInfo: boolean;
    hasSaveDueDateInfo: boolean;
    dueDateCalculation: Array<DueDateCalculationItem>;
    dueDateComparison: Array<DueDateComparisonItem>;
    dueDateSatisfiedBy: Array<DueDateSatisfiedByItem>;
}

export class RemindersInfo {
    formattedDescription: string;
    nameTypes: string;
    names: string;
    subject: string;
    messageInfo: string;
    message: string;
    alternateMessage: string;
}

export class DocumentsInfo {
    formattedDescription: string;
    maxProductionValue?: number;
    requestLetterLiteralFlag: number;
    feesAndChargesInfo: string;
}

export class DueDateSatisfiedByItem {
    eventKey?: number;
    formattedDescription: string;
}

export class DueDateCalculationItem {
    eventKey?: number;
    caseKey?: number;
    caseReference: string;
    cycle?: number;
    formattedDescription: string;
    or?: boolean;
    calculatedFromLabel: string;
    fromDateFormatted: string;
    mustExist?: boolean;
}

export class DueDateComparisonItem {
    leftHandSide: string;
    rightHandSide: string;
    comparison: string;
    leftHandSideEventKey?: number;
    rightHandSideEventKey?: number;
}

export class DatesLogicDetailInfo {
    formattedDescription: string;
    testFailureAction: string;
    messageDisplayed: string;
    failureActionType: string;
}

export enum FailureActionType {
    Warning = 'Warning',
    Error = 'Error'
}

export class EventUpdateInfo {
    updateImmediatelyInfo: boolean;
    updateWhenDueInfo: boolean;
    status: string;
    feesAndChargesInfo: string;
    feesAndChargesInfo2: string;
    createAction: string;
    closeAction: string;
    reportToCpaInfo: string;
    datesToUpdate?: UpdateEventDateItem;
    datesToClear?: Array<string>;
}

export class UpdateEventDateItem {
    formattedDescription: string;
    adjustment: string;
}