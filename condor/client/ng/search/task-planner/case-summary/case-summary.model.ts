export interface CaseSummaryModel {
    caseData: any;
    names: any;
    criticalDates: any;
    nextDueEvent: any;
    lastEvent: any;
}

export interface TaskSummaryModel {
    type: string;
    eventDescription: string;
    dueDate?: Date;
    reminderMessage?: string;
    reminderDate?: Date;
    nextReminderDate?: Date;
    governingEvent?: Date;
    governingEventDesc?: string;
    caseOffice?: string;
    dueDateResponsibility?: string;
    otherRecipients?: string;
    finalizedDate?: Date;
    emailBody: string;
    emailSubject: string;
    forwardedFrom: string;
    adhocResponsibleName: string;
}