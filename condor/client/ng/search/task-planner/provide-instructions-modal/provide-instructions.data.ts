export class ProvideInstructionsViewData {
    eventText: string;
    eventDueDate: Date;
    instructionDate: Date;
    irn: string;
    instructions: Array<CaseInstruction>;
}

export class CaseInstruction {
    caseKey: number;
    instructionCycle: number;
    instructionDefinitionKey: number;
    responseLabel: string;
    instructionName: string;
    instructionExplanation: string;
    responseNo: string;
    actions: Array<CaseInstructionResponse>;
    selectedAction: CaseInstructionResponse;
    eventData: any;
    showEventNote: Boolean;
    eventNameTooltip: string;
    eventNotesGroupTooltip: string;
}

export class CaseInstructionResponse {
    eventNo: number;
    eventName: string;
    eventNotesGroup: string;
    responseSequence: string;
    responseLabel: string;
    responseExplanation: string;
    eventNotes: Array<any>;
}
