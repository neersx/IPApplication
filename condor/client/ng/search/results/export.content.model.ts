export enum ContentStatus {
    readyToDownload = 'ready.to.download',
    processedInBackground = 'processed.in.background',
    executionFailed = 'error'
}

export type ExportContentType = {
    contentId: number;
    reportFormat: string;
};