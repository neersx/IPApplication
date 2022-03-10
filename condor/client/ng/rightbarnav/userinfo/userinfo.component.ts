import { ChangeDetectionStrategy, Component } from '@angular/core';
import { AppContextService } from 'core/app-context.service';
import { take } from 'rxjs/operators';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { ChangePasswordComponent } from './changepassword/changepassword.component';

@Component({
  selector: 'userinfo',
  templateUrl: './userinfo.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class UserInfoComponent {
  appContext: any;
  constructor(private readonly appContextService: AppContextService, private readonly modalService: IpxModalService) {
    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe((ctx) => {
        this.appContext = ctx;
      });
  }
  openChangePasswordModal = (): void => {
    this.modalService.openModal(ChangePasswordComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg'
    });
  };
}
