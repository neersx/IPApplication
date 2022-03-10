import { HttpClient } from '@angular/common/http';
import { EventEmitter, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map, shareReplay, take } from 'rxjs/operators';
import { IpxModalService } from 'shared/component/modal/modal.service';
import * as _ from 'underscore';
import { AttachmentMaintenanceComponent } from './attachment-maintenance/attachment-maintenance.component';
import { AttachmentService } from './attachment.service';
import { AttachmentsModalComponent } from './attachments-modal/attachments-modal.component';

@Injectable()
export class AttachmentModalService {
  modalRef: any;
  attachmentsModified: EventEmitter<any> = new EventEmitter<any>();

  constructor(private readonly http: HttpClient, private readonly modalService: IpxModalService, private readonly attachmentService: AttachmentService) {
  }

  private readonly getViewData = (): Observable<any> => {
    return this.http.get('api/attachment/view').pipe(shareReplay(1));
  };

  viewData$ = this.getViewData();

  displayAttachmentModal = (baseType: 'case' | 'name' | 'activity' | 'priorArt', key: any, eventDetails: any, headerData?: {label: string, value: any}): void => {
    this.modalRef = this.modalService.openModal(AttachmentsModalComponent, {
      backdrop: 'static',
      class: 'modal-xl modal-dms',
      initialState: {
        baseType,
        key,
        eventDetails,
        viewData$: this.viewData$,
        headerData
      }
    });

    this.modalRef.content.dataModified$.pipe(take(1)).subscribe((value) => {
      if (!!value) {
        this.attachmentsModified.emit(value);
      }
    });
  };

  triggerAddAttachment = (baseType: 'case' | 'name' | 'activity', key: any, eventDetails: any): void => {
    this.attachmentService.attachmentMaintenanceView$(baseType, key, eventDetails)
      .pipe(map((result) => {
        if (baseType === 'case' && _.isNumber(key) && eventDetails.eventCycle !== '' && !!result.event && !_.isNumber(result.event.eventCycle)) {
          result.event.cycle = eventDetails.eventCycle;
        }

        return result;
      }), take(1)).subscribe((data) => {
        this.modalRef = this.modalService.openModal(AttachmentMaintenanceComponent, {
          animated: false,
          class: 'modal-xl',
          ignoreBackdropClick: true,
          initialState: {
            viewData: {
              ...data,
              actionKey: !!eventDetails ? eventDetails.actionKey : null,
              id: key,
              baseType
            },
            activityDetails: (!!data.activityDetails ? data.activityDetails : {})
          }
        });

        this.modalRef.content.onClose$.pipe(take(1)).subscribe((value) => {
          if (!!value) {
            this.attachmentsModified.emit(value);
          }
        });
      });
  };
}