import { ChangeDetectionStrategy, Component, OnInit, TemplateRef } from '@angular/core';
import { BsModalService } from 'ngx-bootstrap/modal';

@Component({
  selector: 'ipx-cookie-declaration',
  templateUrl: './cookie-declaration.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CookieDeclarationComponent {
  constructor(private readonly modalService: BsModalService) {

  }

  close = () => {
    this.modalService.hide(1);
  };
}
