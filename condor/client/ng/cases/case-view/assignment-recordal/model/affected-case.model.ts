export class AddAffetcedRequestModel {
    caseId: number;
    relatedCases: Array<string>;
    jurisdiction: string;
    recordalSteps: Array<RecordalStepAddModel>;
    officialNo: string;

    constructor(caseKey) {
        this.caseId = caseKey;
    }
}

export class RecordalStepAddModel {
    recordalStepSequence: number;
    recordalTypeNo: number;
}