import { of } from 'rxjs';

export class SearchExportServiceMock {
    export = jest.fn(); exportToCpaXml = jest.fn();
    generateContentId = jest.fn().mockReturnValue(of([])); removeAllContents = jest.fn().mockReturnValue(of([]));
}