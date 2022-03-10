import { Observable, of } from 'rxjs';

export class GenerateDocumentServiceMock {
    getDataForAdhocDoc$: (callerType: 'CaseView' | 'NameView', caseOrNameKey: number, documentId: number, addAsAttachment: boolean) => Observable<any> = jest.fn().mockReturnValue(of({}));
    generateAndSavePdf$: (callerType: 'CaseView' | 'NameView', caseOrNameKey: number, documentId: number, documentName: string, template: string, saveFileLocation: string, saveFileName: string, entryPoint: string) => Observable<any> = jest.fn().mockReturnValue(of({}));
    getGeneratedPdfDocument$: (callerType: 'CaseView' | 'NameView', caseOrNameKey: number, fileKey: string) => Observable<any> = jest.fn().mockReturnValue(of({}));
}