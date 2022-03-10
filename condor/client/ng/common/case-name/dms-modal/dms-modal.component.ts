import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { DmsTopic } from '../dms/dms.component';

@Component({
  selector: 'app-dms-modal',
  templateUrl: './dms-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DmsModalComponent implements OnInit {
  topic: DmsTopic;
  @Input() caseKey: number;
  @Input() nameKey: number;
  @Input() isMaintainance: boolean;
  onClose$ = new Subject();
  iwl: string;
  docName: string;

  constructor(readonly bsModalRef: BsModalRef) { }

  ngOnInit(): void {
    this.topic = new DmsTopic({
      callerType: this.nameKey ? 'NameView' : 'CaseView',
      viewData: {
        caseKey: this.caseKey,
        nameId: this.nameKey
      }
    });
  }

  iwlChanged(doc: { link: string, description: string }): void {
    this.iwl = doc.link;
    this.docName = doc.description;
  }

  apply(): void {
    this.bsModalRef.hide();
    this.onClose$.next({ iwl: this.iwl });
  }

  close(): void {
    this.bsModalRef.hide();
    this.onClose$.next();
  }
}
