import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit } from '@angular/core';
import { AppContextService } from 'core/app-context.service';

@Component({
  selector: 'ipx-top-header',
  templateUrl: './ipx-top-header.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TopHeaderComponent implements OnInit {
  baseUrl = '../';
  showLink = false;
  showTimerInfo = false;
  ctxLoaded = false;

  constructor(private readonly appContextService: AppContextService, public el: ElementRef, private readonly cdr: ChangeDetectorRef) { }

  ngOnInit(): any {
    if (this.el.nativeElement.getAttribute('ishosted') != null) {
      this.appContextService.isHosted = true;

      return;
    }

    this.appContextService.appContext$.subscribe(ctx => {
      this.showLink = ctx
        ? ctx.user
          ? ctx.user.permissions.canShowLinkforInprotechWeb === true
          : false
        : false;
      this.showTimerInfo = (!!ctx && !!ctx.user && !!ctx.user.permissions) ? ctx.user.permissions.canAccessTimeRecording : false;
      this.ctxLoaded = true;
      this.cdr.markForCheck();
    });
  }
}
