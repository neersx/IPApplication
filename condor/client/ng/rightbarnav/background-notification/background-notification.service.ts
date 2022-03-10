import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { FileDownloadService } from 'shared/shared-services/file-download.service';
import * as _ from 'underscore';

export enum ProcessType {
  NotSet,
  GlobalNameChange,
  GlobalCaseChange,
  UserAdministration,
  DebtorStatementRequest,
  StandardReportRequest,
  CpaXmlExport,
  CpaXmlForImport,
  SanityCheck,
  BillPrint,
  ExportPdf,
  ExportWord,
  ExportExcel
}

export enum StatusType {
  NotSet,
  Started,
  Completed,
  Error,
  Information,
  Hidden
}

export enum ProcessSubType {
  NotSet,
  Policing,
  TimePosting
}

export class BackgroundNotificationMessage {
  constructor(public processId: number, public identityId: number, public processName: string, public statusDate: Date, public statusInfo: string, public status: string, public tooltip: string, public processType: string, public processSubType: string) {
  }
}

@Injectable()
export class BackgroundNotificationService {

  private readonly _messages: BehaviorSubject<Array<BackgroundNotificationMessage>> = new BehaviorSubject<Array<BackgroundNotificationMessage>>([]);

  private readonly _apiBase = 'api/backgroundProcess';
  private readonly _apiExportContent = 'api/export/download';
  constructor(
    readonly translate: TranslateService,
    readonly http: HttpClient,
    readonly fileDownloadService: FileDownloadService
  ) { }

  setProcessIds = (processIds: Array<number>) => {
    this.getMessages();
  };

  downloadCpaXmlExport = (processId: number): void => {
    this.fileDownloadService.downloadFile(this._apiBase + '/cpaXmlExport?processId=' + processId, null);
  };

  downloadExportContent = (processId: number): void => {
    this.fileDownloadService.downloadFile(this._apiExportContent + '/process/' + processId, null);
  };

  private readonly getMessages = (): void => {
    this.http.get(this._apiBase + '/list').subscribe((m: Array<any>) => {
      this._messages.next(this.convertToBMessages(m));
    });
  };

  readMessages$ = (): Observable<Array<BackgroundNotificationMessage>> => {
    return this._messages.asObservable();
  };

  private readonly deleteMessages = (processIds: Array<number>): Observable<any> => {
    return this.http.post(this._apiBase + '/delete', processIds);
  };

  deleteProcessIds = (processIds: Array<number>) => {
    if (processIds) {
      return this.deleteMessages(processIds);
    }
    const currentMessageIds = _.pluck(this._messages.getValue(), 'processId');

    return this.deleteMessages(currentMessageIds);
  };

  private readonly convertToBMessages = (newMessages: Array<any>): Array<BackgroundNotificationMessage> => {
    const messages = new Array<BackgroundNotificationMessage>();
    newMessages.forEach(m => {
      const processName: string = m.processSubType != null ? m.processSubType.toLowerCase() : m.processType.toLowerCase();
      messages.push(
        new BackgroundNotificationMessage(
          m.processId,
          m.identityId,
          processName === ProcessType[ProcessType.StandardReportRequest].toLowerCase() ? m.fileName : this.translate.instant('backgroundNotifications.processTypes.' + processName),
          m.statusDate,
          m.statusInfo,
          this.translate.instant('backgroundNotifications.statusType.' + m.statusType),
          m.statusType === StatusType.Error ? this.translate.instant('backgroundNotifications.error.' + m.statusType) : this.translate.instant('backgroundNotifications.tooltips.' + processName),
          m.processType,
          m.processSubType
        ));
    });

    return messages;
  };
}
