import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { AppContextService } from 'core/app-context.service';
import { take } from 'rxjs/operators';
import { LinkService, LinksViewModel } from './links.service';

@Component({
  selector: 'links',
  templateUrl: './links.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class LinksComponent implements OnInit {

  links: Array<LinksViewModel>;
  appContext: any;

  constructor(private readonly appContextService: AppContextService, private readonly service: LinkService, private readonly cdref: ChangeDetectorRef) {
  }

  ngOnInit(): void {
    this.service.get()
      .subscribe((data: Array<LinksViewModel>) => {
        this.links = data;
        this.cdref.detectChanges();
      });

    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe((ctx) => {
        this.appContext = ctx;
        this.cdref.detectChanges();
      });
  }

  trackByFn = (index: number, item: any) => {
    return index;
  };
}
