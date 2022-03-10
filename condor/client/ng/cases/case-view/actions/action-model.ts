export class ActionModel {
    actionId: string;
    name: string;
    criteriaId: number;
    cycle: number;
    importanceLevel: number;
    constructor(actionId: string, name: string, criteriaId: number, cycle: number, importanceLevel: number, public isCyclic: boolean, public canMaintainWorkflow: boolean, public hasEditableCriteria: boolean, public isPotential: boolean, public isOpen: boolean) {
        this.actionId = actionId;
        this.name = name;
        this.criteriaId = criteriaId;
        this.cycle = cycle;
        this.importanceLevel = importanceLevel;
    }
}

export class ActionEventsRequestModel {
    criteria: ActionEventsCriteria;
    params: any;
}

export class ActionEventsCriteria {
    caseKey: number;
    actionId: string;
    criteriaId: number;
    cycle?: number;
    importanceLevel?: number;
    isCyclic?: boolean;
    isAllEvents?: boolean;
    isAllCycles?: boolean;
    isMostRecentCycle?: boolean;
}
