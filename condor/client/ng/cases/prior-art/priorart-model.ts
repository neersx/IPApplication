export class PriorArtSaveModel {
    evidence: any;
    country: string;
    officialNumber: string;
    sourceDocumentId?: number;
    source: string;
    caseKey?: number;
}

export type PriorArtStep = {
    id: number;
    selected: boolean;
    stepData?: any;
    isDefault: boolean;
    title: string;
};

export enum PriorArtType {
    Ipo = 1,
    Literature = 2,
    Source = 3,
    NewSource = 4
}

export enum LinkType {
    Family = 1,
    CaseList = 2,
    Name = 3
}

export enum IpoSearchType {
    Single = 1,
    Multiple = 2
}