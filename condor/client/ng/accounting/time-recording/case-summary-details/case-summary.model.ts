export interface CaseSummaryModel {
    caseKey: string;
    caseReference: string;
    title: string;
    caseStatus: string;
    renewalStatus: string;
    officialNumber: string;
    instructor: any;
    debtors: Array<any>;
    owners: Array<any>;
    staffMember: string;
    signatory: string;
    activeBudget: number;
    caseNarrativeText: string;
    enableRichText: boolean;
}
