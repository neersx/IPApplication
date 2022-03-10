import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { FileLocationPermissions } from '../file-locations.component';

@Component({
  selector: 'file-history',
  templateUrl: './file-history.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class FileHistoryComponent implements OnInit {
  topic: Topic;
  irn: string;
  permissions: FileLocationPermissions;
  fileHistoryFromMaintenance: boolean;
  filePartId: number;

  constructor(private readonly modalService: IpxModalService) { }

  ngOnInit(): void {
    this.irn = this.topic.params.viewData.irn;
  }

  cancel(): void {
    this.modalService.modalRef.hide();
  }
}
