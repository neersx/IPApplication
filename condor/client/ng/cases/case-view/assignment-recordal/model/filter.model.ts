export class AffectedCasesFilterModel {

    filters: Array<FilterValue>;
    jurisdictions: [];
    caseStatus: [];
    recordalStatus: [];
    stepNo: number;
    ownerId: number;
    recordalTypeNo: number;
    caseReference: string;
}

export class FilterValue {
    operator?: string;
    field: string;
    value: any;
    type?: string;
}