import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { PopoverDirective } from 'ngx-bootstrap/popover';
import { takeUntil } from 'rxjs/operators';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { AttachmentPopupService } from './attachment-popup.service';

@Component({
  selector: 'ipx-attachments-popover',
  templateUrl: './attachments-popup.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class AttachmentsPopupComponent implements OnInit {
  @Input() caseKey: number;
  @Input() eventNo: number;
  @Input() eventCycle: number;
  @Input() total: number;

  dataRetrivable = false;

  @ViewChild(PopoverDirective) popover: PopoverDirective;

  attachments: Array<any>;
  isLoading: boolean;

  constructor(private readonly popupService: AttachmentPopupService, private readonly cdr: ChangeDetectorRef, private readonly destroy$: IpxDestroy) { }
  ngOnInit(): void {
    this.dataRetrivable = _.isNumber(this.caseKey) && _.isNumber(this.eventNo) && _.isNumber(this.eventCycle);
  }

  getUrl = ($event, dataItem: any): void => {
    $event.stopPropagation();
    const allowedAttachmentTypes = ['http', 'iwl'];
    const filePath: string = dataItem.filePath;
    const openClientDirectly = _.any(allowedAttachmentTypes, (a) => {
      return filePath && filePath.toLowerCase().startsWith(a);
    });

    const url = openClientDirectly ? filePath :
      'api/attachment/file?activityKey=' + dataItem.activityId + '&sequenceKey=' + dataItem.sequenceNo + '&path=' + encodeURIComponent(dataItem.filePath);

    window.open(url);
  };

  onClick = () => {
    this.popupService.hideExcept(undefined);
  };

  onShown = () => {
    this.isLoading = true;
    this.popupService.hideExcept(this.popover);
    this.popupService.getAttachments$(this.caseKey, this.eventNo, this.eventCycle)
      .pipe(takeUntil(this.destroy$))
      .subscribe(data => {
        this.attachments = data;
        this.isLoading = false;
        this.cdr.markForCheck();
      });
  };

  trackByIndex = (index): any => {
    return index;
  };
}