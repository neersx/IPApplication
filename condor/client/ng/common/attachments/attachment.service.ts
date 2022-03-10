import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import * as _ from 'underscore';
@Injectable({
  providedIn: 'root'
})
export class AttachmentService {

  constructor(private readonly http: HttpClient) {
  }

  getUrl = (baseType: string, path?: string) => `api/attachment/${baseType}${!!path ? '/' + path : ''}`;

  getAttachments$(baseType: string, id: number, queryParams: GridQueryParameters): Observable<any> {
    if (!_.isNumber(id) || !baseType) { return undefined; }

    const url = 'api/' + baseType + '/' + id.toString() + '/attachments';

    return this.http.get(url, {
      params: {
        params: JSON.stringify(queryParams)
      }
    });
  }

  attachmentMaintenanceView$(baseType: string, id: number, params: any): Observable<any> {
    if (!baseType) { return undefined; }

    const url = this.getUrl(baseType, `view/${_.isNumber(id) ? id : ''}`);

    return this.http.get(url, {
      params
    });
  }

  getAttachment$(baseType: string, id: number, activityId: string, sequence: string): Observable<any> {
    if (baseType == null || activityId == null) { return of(null); }

    const idString = _.isNumber(id) ? id.toString() : '';

    return this.http.get(this.getUrl(baseType, idString), {
      params: {
        activityId,
        sequence
      }
    });
  }

  addOrUpdateAttachment$(baseType: string, id: number, attachment: any): Observable<any> {
    if (!attachment) { return undefined; }

    if (!_.isNumber(attachment.sequenceNo)) {

      return this.http.put(this.getUrl(`new/${baseType}`, _.isNumber(id) ? id.toString() : ''), attachment);
    }

    return this.http.put(this.getUrl(`update/${baseType}`, _.isNumber(id) ? id.toString() : ''), attachment);
  }

  validateDirectory$(path: string): Observable<any> {
    if (!path) { return of(null); }
    const apiEndPoint = 'api/attachment/validateDirectory';

    return this.http.get(apiEndPoint, {
      params: {
        path
      }
    });
  }
  validatePath$(path: string): Observable<any> {
    if (!path) { return of(null); }
    const apiEndPoint = 'api/attachment/validatePath';

    return this.http.get(apiEndPoint, {
      params: {
        path
      }
    });
  }
  getStorageLocation(path: string): Observable<any> {
    if (!path) { return undefined; }

    return this.http.get('api/attachment/storageLocation', {
      params: {
        path
      }
    });
  }

  deleteAttachment(baseType: string, id: number, attachment: any, activityApi: boolean): Observable<any> {
    const url = (baseType === 'activity' || !activityApi) ?
      this.getUrl(`delete/${baseType}`, _.isNumber(id) ? id.toString() : '') : this.getUrl(`delete/${baseType}`, _.isNumber(id) ? `${id.toString()}/${activityApi}` : '');

    return this.http.request('delete', url, { body: attachment });
  }

  getDeliveryDestination$ = (baseType: string, caseOrNameKey: number, documentId: number): Observable<any> => {

    return this.http.get(this.getUrl(`${baseType}`, caseOrNameKey + '/document/' + documentId + '/delivery-destination'));
  };

  getActivity$ = (baseType: string, caseOrNameKey: number, documentId: number): Observable<any> => {

    return this.http.get(this.getUrl(`${baseType}`, caseOrNameKey + '/document/' + documentId + '/activity'));
  };
}

export class AttachmentModel {
  activityId?: number;
  sequenceNo?: number;
  activityCategoryId: string;
  activityDate?: Date;
  activityType: string;
  attachmentName: string;
  attachmentType: string;
  eventCycle: number;
  eventId: string;
  filePath: string;
  isPublic?: boolean | false;
  language: string;
  pageCount: number;
  priorArtId?: number;

  constructor(data?: any) {
    return Object.assign(this, data);
  }
}
