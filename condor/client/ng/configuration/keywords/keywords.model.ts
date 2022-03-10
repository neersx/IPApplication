export class KeywordsPermissions {
    canAdd: boolean;
    canEdit: boolean;
    canDelete: boolean;
}

export class KeywordItems {
    keywordNo?: number;
    keyword: string;
    stopCaseKeyWord: boolean;
    stopNameKeyword: boolean;
    synonyms: any;
}

export enum BulkOperationType {
    DeleteKeywords = 'DeleteAffectedCases',
    ClearKeywords = 'ClearAffectedCaseAgent',
    EditKeywords = 'EditrAffectedCaseAgent'
}