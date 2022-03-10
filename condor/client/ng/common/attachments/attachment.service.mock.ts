import { Observable, of } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';

export class AttachmentServiceMock {
    getAttachments$: (baseType: string, id: number, queryParams: GridQueryParameters) => Observable<jest.Mock> = jest.fn();
    attachmentMaintenanceView$ = jest.fn();
    getAttachment$ = jest.fn();
    addOrUpdateAttachment$ = jest.fn();
    validatePath$: (path: string) => Observable<jest.Mock> = jest.fn();
    validateDirectory$: (path: string) => Observable<jest.Mock> = jest.fn();
    deleteAttachment = jest.fn();
    getStorageLocation: (path: string) => Observable<any> = jest.fn();
    getDeliveryDestination$: (baseType: string, caseOrNameKey: number, documentId: number) => Observable<any> = jest.fn();
    getActivity$: (baseType: string, caseOrNameKey: number, documentId: number) => Observable<any> = jest.fn();
}