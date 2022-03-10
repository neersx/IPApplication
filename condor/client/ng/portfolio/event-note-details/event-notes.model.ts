export class EventNotesData {
    eventNoteType?: number;
    eventText: string;
    replaceNote: boolean;
    caseEventId: number;
}

export enum eventNoteEnum {
    taskPlanner = 'taskPlanner',
    actionEvent = 'actionEvent',
    provideInstructions = 'provideInstructions'
}

export class EventNoteViewData {
    friendlyName: string;
    timeFormat: string;
    dateStyle: string;
}