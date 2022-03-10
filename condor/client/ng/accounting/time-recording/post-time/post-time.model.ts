export interface PostTimeView {
    entities?: Array<{ id: number, displayName: string, isDefault: boolean }>;
    hasFixedEntity?: boolean;
    postToCaseOfficeEntity?: boolean;
}

export class PostResult {
    rowsPosted?: number;
    rowsIncomplete?: number;
    hasOfficeEntityError: boolean;
    hasError: boolean;
    hasWarning: boolean;
    error?: any;
    isBackground: boolean;
}