import { ChangeDetectionStrategy, Component } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';

@Component({
  selector: 'ipx-full-image',
  templateUrl: './image-full.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ImageFullComponent {
  itemKey: string;
  imageKey: number;
  imageTitle: string;
  queryContext: number;
  titleLimit: number;
  type: string;

  private readonly modalRef: BsModalRef;

  constructor(bsModalRef: BsModalRef) {
    this.modalRef = bsModalRef;
    this.titleLimit = 80;
  }

  close = (): void => {
    this.modalRef.hide();
  };
}
