export class PicklistModel {
    key: any;
    code: string;
    value: string;
}

export class CaseRelatedDataModel {
    office: PicklistModel;
    caseType: PicklistModel;
    propertyType: PicklistModel;
    jurisdiction: PicklistModel;
    category: PicklistModel;
    basis: PicklistModel;
    subType: PicklistModel;

    statusIncludeDead: boolean;
    statusIncludePending: boolean;
    statusIncludeRegistered: boolean;
}

export class CaseNameRelatedDataModel {
    nameType: PicklistModel;
    family: PicklistModel;
    name: PicklistModel;
}

export class OtherDataModel {
    instruction: PicklistModel;
    characteristics: PicklistModel;
    tableCode: PicklistModel;
    roleByPassError: PicklistModel;
    sanityCheckItem: PicklistModel;
    event: PicklistModel;
    eventIncludeDue: boolean;
    eventIncludeOccurred: boolean;
}

export class DataValidation {
    id: number;
    inUseFlag: boolean;
    deferredFlag: boolean;
    displayMessage: string;
    ruleDescription: string;
    notes: string;
    isWarning: boolean;

    eventdateflag: number;
    statusFlag: number;
    localclientFlag: boolean;
    usedasFlag: number;
    notCaseType: boolean;
    notCountryCode: boolean;
    notPropertyType: boolean;
    notCaseCategory: boolean;
    notSubtype: boolean;
    notBasis: boolean;
}

export class SanityCheckRuleModel {
    dataValidation: DataValidation;
    caseDetails: CaseRelatedDataModel;
    caseNameDetails: CaseNameRelatedDataModel;
    otherDetails: OtherDataModel;
}

export class SanityCheckNameRule {
    ruleOverView: RuleOverView;
    nameCharacteristics: NameCharacteristics;
    standingInstruction: StandingInstruction;
    other: Other;
}
export class NamesSanityCheckRuleModel extends SanityCheckNameRule {
    constructor(data?: any) {
        super();
        if (!!data) {
            if (!!data.nameCharacteristics && !!data.nameCharacteristics.nameGroup) {
                data.nameCharacteristics.nameGroup.title = data.nameCharacteristics.nameGroup.value;
            }
            if (!!data.nameCharacteristics && !!data.nameCharacteristics.name) {
                data.nameCharacteristics.name.displayName = data.nameCharacteristics.name.value;
            }
            if (!!data.standingInstruction && !!data.standingInstruction.characteristic) {
                data.standingInstruction.characteristic.description = data.standingInstruction.characteristic.value;
            }

            Object.assign(this, data);
        }
    }
}
export class SanityCheckRuleModelEx extends SanityCheckRuleModel {
    constructor(data?: any) {
        super();
        if (!!data) {
            Object.assign(this, data);
        }
    }

    private readonly convertRuleOverview = (): RuleOverView => {
        const ruleOverView: RuleOverView = !!this.dataValidation ? {
            ruleDescription: this.dataValidation.ruleDescription,
            displayMessage: this.dataValidation.displayMessage,
            notes: this.dataValidation.notes,
            informationOnly: this.dataValidation.isWarning,
            inUse: this.dataValidation.inUseFlag,
            deferred: this.dataValidation.deferredFlag,
            sanityCheckSql: this.otherDetails.sanityCheckItem,
            mayBypassError: this.otherDetails.roleByPassError
        } : {} as any;

        return ruleOverView;
    };

    private readonly convertStandingInstruction = (): StandingInstruction => {
        const standingInstruction: StandingInstruction = !!this.otherDetails ? {
            instructionType: this.otherDetails.instruction,
            characteristic: { ...this.otherDetails.characteristics, ...{ description: this.otherDetails.characteristics?.value } }
        } : {} as any;

        return standingInstruction;
    };

    private readonly convertOther = (): Other => {
        const other: Other = !!this.otherDetails ? {
            tableColumn: this.otherDetails.tableCode
        } : {} as any;

        return other;
    };

    convertToCaseRuleModel = (): SanityCheckCaseRule => {
        const ruleOverView: RuleOverView = this.convertRuleOverview();

        const caseDetails: CaseCharacteristics = !!this.caseDetails ? {
            caseOffice: this.caseDetails.office,
            caseType: this.caseDetails.caseType,
            jurisdiction: this.caseDetails.jurisdiction,
            propertyType: this.caseDetails.propertyType,
            caseCategory: this.caseDetails.category,
            subType: this.caseDetails.subType,
            basis: this.caseDetails.basis,
            caseTypeExclude: this.dataValidation.notCaseType,
            jurisdictionExclude: this.dataValidation.notCountryCode,
            propertyTypeExclude: this.dataValidation.notPropertyType,
            caseCategoryExclude: this.dataValidation.notCaseCategory,
            subTypeExclude: this.dataValidation.notSubtype,
            basisExclude: this.dataValidation.notBasis,
            applyTo: this.dataValidation.localclientFlag == null ? null : !!this.dataValidation.localclientFlag ? 1 : 0,
            statusIncludePending: this.caseDetails.statusIncludePending,
            statusIncludeRegistered: this.caseDetails.statusIncludeRegistered,
            statusIncludeDead: this.caseDetails.statusIncludeDead
        } : {} as any;

        const caseName: CaseName = !!this.caseNameDetails ? {
            nameGroup: { ...this.caseNameDetails.family, ...{ title: this.caseNameDetails.family?.value } },
            name: { ...this.caseNameDetails.name, ...{ displayName: this.caseNameDetails.name?.value } },
            nameType: this.caseNameDetails.nameType
        } : {} as any;

        const event: EventModel = !!this.otherDetails ? {
            event: this.otherDetails.event,
            eventIncludeDue: this.otherDetails.eventIncludeDue,
            eventIncludeOccurred: this.otherDetails.eventIncludeOccurred
        } : {} as any;

        const standingInstruction: StandingInstruction = this.convertStandingInstruction();

        const other: Other = this.convertOther();

        return {
            ruleOverView,
            caseCharacteristics: caseDetails,
            caseName,
            standingInstruction,
            event,
            other
        };
    };
}

export class RuleOverView {
    ruleDescription: string;
    displayMessage: string;
    notes: string;
    informationOnly: boolean;
    inUse: boolean;
    deferred: boolean;
    sanityCheckSql: PicklistModel;
    mayBypassError: PicklistModel;
}

export class CaseCharacteristics {
    caseOffice: PicklistModel;
    caseType: PicklistModel;
    jurisdiction: PicklistModel;
    propertyType: PicklistModel;
    caseCategory: PicklistModel;
    subType: PicklistModel;
    basis: PicklistModel;

    caseTypeExclude: boolean;
    jurisdictionExclude: boolean;
    propertyTypeExclude: boolean;
    caseCategoryExclude: boolean;
    subTypeExclude: boolean;
    basisExclude: boolean;

    statusIncludePending: boolean;
    statusIncludeRegistered: boolean;
    statusIncludeDead: boolean;

    applyTo: number;
}

export class NameCharacteristics {
    name: PicklistModel;
    nameGroup: any;
    jurisdiction: PicklistModel;
    category: PicklistModel;
    applyTo: number;

    // TODO: status related fields
}

export class CaseName {
    nameGroup: any;
    name: PicklistModel;
    nameType: PicklistModel;
}

export class EventModel {
    event: PicklistModel;
    eventIncludeDue: boolean;
    eventIncludeOccurred: boolean;
}

export class StandingInstruction {
    instructionType: PicklistModel;
    characteristic: any;
}

export class Other {
    tableColumn: PicklistModel;
}

export class SanityCheckCaseRule {
    ruleOverView: RuleOverView;
    caseCharacteristics: CaseCharacteristics;
    standingInstruction: StandingInstruction;
    caseName: CaseName;
    event: EventModel;
    other: Other;
}
