import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class GenerateDocumentService {
    constructor(private readonly http: HttpClient) {
    }

    private readonly getApiWithType = (callerType): string => {
        const type = callerType === 'NameView' ? 'name' : 'case';

        return `api/attachment/${type}/`;
    };

    getDataForAdhocDoc$ = (callerType: 'CaseView' | 'NameView', caseOrNameKey: number, documentId: number, addAsAttachment: boolean): Observable<any> => {
        return this.http.get(this.getApiWithType(callerType) + caseOrNameKey + '/document/' + documentId + '/data', {
            params:
            {
                addAsAttachment: addAsAttachment.toString()
            }
        });
    };

    getGeneratedPdfDocument$ = (callerType: 'CaseView' | 'NameView', caseOrNameKey: number, fileKey: string): Observable<any> => {

        return this.http.get(this.getApiWithType(callerType) + caseOrNameKey + '/document/get-pdf?fileKey=' + fileKey,
            { responseType: 'blob' }
        );
    };

    generateAndSavePdf$ = (callerType: 'CaseView' | 'NameView', caseOrNameKey: number, documentId: number, documentName: string, template: string, saveFileLocation: string, saveFileName: string, entryPoint: string): Observable<any> => {
        return this.http.post(this.getApiWithType(callerType) + caseOrNameKey + '/document/generate-pdf', {
            DocumentId: documentId,
            DocumentName: documentName,
            Template: template,
            SaveFileLocation: saveFileLocation,
            SaveFileName: saveFileName,
            EntryPoint: entryPoint
        });
    };
}