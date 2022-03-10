import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { WindowRef } from 'core/window-ref';

@Component({
  selector: 'ipx-file-instruct-link',
  templateUrl: './file-instruct-link.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class FileInstructLinkComponent implements OnInit {
  @Input() caseKey: string;
  @Input() isFiled: Boolean;
  @Input() canAccess: Boolean;

  constructor(private readonly notificationService: NotificationService,
    private readonly http: HttpClient,
    private readonly windowRef: WindowRef) { }

  ngOnInit(): void {
    this.showLink = this.isFiled && this.canAccess;
    this.showIconOnly = this.isFiled && !this.canAccess;
  }
  showLink: Boolean;
  showIconOnly: Boolean;

  link = () => {
    return this.http.put<{ result: FileInstructResponse }>('api/ip-platform/file/view-filing-instruction?caseKey=' + this.caseKey, null)
      .toPromise()
      .then((response) => {
        const r = response.result;
        if (r.progressUri) {
          return this.windowRef.nativeWindow.open(r.progressUri, '_blank');
        }

        return this.notificationService.alert({
          title: 'modal.unableToComplete',
          message: r.errorDescription
        });
      });
  };
}

export class FileInstructResponse {
  progressUri: string;
  errorDescription: string;
}
