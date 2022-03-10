'use strict';

export class KotTextTypesItems {
    id: number;
    caseTypes: string;
    nameTypes: string;
    textType: string;
    roles?: string;
    modules?: string;
    statusSummary?: string;
    backgroundColor?: string;
}

export class KotTextType {
    id?: number;
    textType: PicklistModal;
    caseTypes?: Array<PicklistModal>;
    nameTypes?: Array<PicklistModal>;
    roles?: Array<PicklistModal>;
    hasCaseProgram: boolean;
    hasNameProgram: boolean;
    hasTimeProgram: boolean;
    hasBillingProgram: boolean;
    hasTaskPlannerProgram: boolean;
    isPending: boolean;
    isRegistered: boolean;
    isDead: boolean;
    backgroundColor?: string;
}

export class PicklistModal {
    key: number;
    code: string;
    value: string;
}

export class KotPermissionsType {
    maintainKeepOnTopNotesCaseType: boolean;
    maintainKeepOnTopNotesNameType: boolean;
}

export enum KotFilterTypeEnum {
    byCase = 'c',
    byName = 'n'
}

export class KotFilterCriteria {
    type: KotFilterTypeEnum;
    modules?: Array<string>;
    statuses?: Array<string>;
    roles?: Array<string>;
}