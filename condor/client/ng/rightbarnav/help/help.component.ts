import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, Optional } from '@angular/core';
import { AppContextService } from 'core/app-context.service';
import { take } from 'rxjs/operators';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { CookieDeclarationComponent } from './cookie-declaration/cookie-declaration.component';
import { HelpModel, HelpService } from './help.service';
import { ThirdPartySoftwareLicensesComponent } from './thirdpartysoftwarelicenses/thirdpartysoftwarelicenses.component';

@Component({
  selector: 'help',
  templateUrl: './help.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class HelpComponent implements OnInit {

  helpData: HelpModel;
  appContext: any;
  modalRef: any;

  constructor(private readonly helpService: HelpService,
    private readonly appContextService: AppContextService,
    private readonly modalService: IpxModalService,
    private readonly cdref: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.helpService.get()
      .subscribe((data: HelpModel) => {
        this.helpData = data;
        this.cdref.detectChanges();
      });

    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe((ctx) => {
        this.appContext = ctx;
        this.cdref.detectChanges();
      });
  }

  showCookies(): void {
    this.modalService.openModal(CookieDeclarationComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg'
    });
  }
  showCredits = (): void => {
    if (this.modalRef) { return; }
    this.modalRef = this.modalService.openModal(ThirdPartySoftwareLicensesComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState: {
        credits: this.helpData.credits
      }
    });

    return this.modalRef;
  };

  hasintegrationDBVersion(): boolean {
    return this.appContext && this.appContext.integrationVersion !== null && this.appContext.integrationVersion !== '';
  }
}