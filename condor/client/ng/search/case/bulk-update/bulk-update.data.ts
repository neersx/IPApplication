export class BulkUpdateViewData {
    entitySizes: Array<DropDownData>;
    textTypes: Array<DropDownData>;
    canMaintainFileTracking: boolean;
    canUpdateBulkStatus: boolean;
}

export class DropDownData {
    key: string;
    value: string;
}

export class BulkUpdateData {
    [name: string]: BulkSaveData | BulkCaseTextUpdate | BulkFileLocationUpdate | BulkCaseStatusUpdate;
}

export class BulkSaveData {
    labelTranslationKey: string;
    key: string;
    value?: string;
    toRemove?: boolean;
}

export class BulkCaseTextUpdate {
    labelTranslationKey: string;
    textType: string;
    language?: string;
    toRemove?: boolean;
    canAppend: boolean;
    notes?: string;
    value: string;
}

export class BulkCaseNameReferenceUpdate {
    labelTranslationKey: string;
    nameType: string;
    toRemove?: boolean;
    value: string;
    reference: string;
}

export class BulkFileLocationUpdate {
    labelTranslationKey: string;
    fileLocation?: number;
    movedBy?: number;
    bayNumber?: string;
    whenMoved: Date;
    toRemove: boolean;
    value: string;
}

export class BulkCaseStatusUpdate {
    statusCode: string;
    isRenewal: boolean;
    toRemove?: boolean;
    value: string;
    confirmStatus: boolean;
    password?: string;
}

export class BulkUpdateReasonData {
    textType: any;
    notes: string;
}