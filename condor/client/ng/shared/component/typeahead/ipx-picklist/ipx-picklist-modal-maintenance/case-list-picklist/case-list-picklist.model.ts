export class CaseList {
    key?: number;
    value?: string;
    description?: string;
    primeCase?: any;
    caseKeys: Array<number>;
    newlyAddedCaseKeys: Array<number>;
}

export class CaseListItem {
    caseKey: number;
    caseRef: string;
    officialNumber: string;
    title: string;
    isPrimeCase: Boolean;
}