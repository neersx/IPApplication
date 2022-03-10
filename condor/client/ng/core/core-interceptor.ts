import { HttpErrorResponse, HttpEvent, HttpHandler, HttpInterceptor, HttpProgressEvent, HttpRequest, HttpResponse } from '@angular/common/http';
import { Injectable, Injector } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { ModalService } from 'ajs-upgraded-providers/modal-service.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { AppContextService } from 'core/app-context.service';
import { Observable, of } from 'rxjs';
import { concat, delay, take, tap } from 'rxjs/operators';

@Injectable()
export class CoreInterceptor implements HttpInterceptor {

  private readonly byPassErrors = [
    'Invalid File Extension'
  ];

  constructor(
    private readonly notificationService: NotificationService,
    private readonly modalService: ModalService,
    private readonly translateService: TranslateService,
    private readonly appContextService: AppContextService
  ) { }

  private readonly getLoginScreenUrl = (): string => `signin#/?goto=${encodeURIComponent(window.location.href)}`;
  private readonly showLoginPopup = () => {
    if (!this.modalService.isOpen('Login')) {
      this.modalService.open('Login')
        .catch(() => {
          window.location.href = this.getLoginScreenUrl();
        });
    }
  };

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(request).pipe(
      tap((event: HttpEvent<any>) => {
        if (event instanceof HttpResponse) {
          const body = event.body || {};
          if (body.status === 'unauthorised-credentials') {
            this.showLoginPopup();
          }
        }
      }, (err: any) => {
        if (err instanceof HttpErrorResponse) {
          const cancelled = err.status === -1;

          if (err.status === 401) {
            if (this.appContextService.appContext) {
              this.showLoginPopup();
            } else {
              window.location.href = this.getLoginScreenUrl();
            }
          } else if (!(cancelled)) {
            if (err.error && this.byPassErrors.indexOf(err.error) > -1) {

              return;
            }
            this.translateErrorMessage(err.status === 0 ? 1 : err.status, err.error ? err.error.correlationId : null);
          }
        }
      }));
  }

  translateErrorMessage = (status, correlationId) => {
    const prefix: any = 'common.errors.status-';
    let id: string;
    // tslint:disable-next-line: prefer-conditional-expression
    if (status === 500 && correlationId) {
      id = '500-with-token';
    } else if ([1, 403, 404, 500].indexOf(status) !== -1) {
      id = status;
    } else {
      id = 'other';
    }

    id = prefix + id;

    this.translateService.get(id, { correlationId })
      .pipe(take(1))
      .subscribe((msg: string) => {
        this.notificationService.alert({
          message: msg
        });
      }, () => {
        this.notificationService.alert({
          title: 'Error',
          message: 'common.errors.status-other',
          okButton: 'Ok'
        });
      });
  };
}
