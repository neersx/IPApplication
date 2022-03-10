import { Injectable, NgZone } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { MessageBroker } from 'core/message-broker';
import { WindowRef } from 'core/window-ref';

@Injectable()
export class GraphIntegrationService {

  constructor(
    private readonly messageBroker: MessageBroker,
    private readonly winRef: WindowRef,
    private readonly zone: NgZone,
    private readonly notificationService: NotificationService,
    private readonly translate: TranslateService
  ) { }

  login = (dataItem: any): Promise<boolean> => {
    return new Promise((resolve) => {
      const binding = 'graph.oauth2.login.' + dataItem.identityId;
      this.messageBroker.subscribe(binding, (data) => {
        this.zone.runOutsideAngular(() => {
          if (data && data.status === 'Complete') {
            this.notificationService.success(this.translate.instant('backgroundNotifications.graphMessages.successMessage'));
            resolve(true);
          }
          if (data && data.status === 'Failed') {
            this.notificationService.alert({ message: data.messageId });
            resolve(false);
          }
        });
      });
      this.messageBroker.connect();
      this.navigateWithTimeInterval(dataItem);
    });
  };

  private navigateWithTimeInterval(dataItem): void {
    const interval = setInterval(() => {
      const connectionId = this.messageBroker.getConnectionId();
      if (connectionId) {
        clearInterval(interval);
        const w = this.winRef.nativeWindow.open('api/graph/authorize/' + encodeURIComponent(connectionId) + '/' + dataItem.processId, '_blank');
        if (w) {
          w.onerror = () => console.log('error occured');
        }
      }
    }, 200);
  }

}
