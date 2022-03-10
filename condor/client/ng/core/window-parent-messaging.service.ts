import { Injectable } from '@angular/core';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { WindowRef } from './window-ref';

@Injectable({
  providedIn: 'root'
})
export class WindowParentMessagingService {
  isHosted = false;

  constructor(rootScopeService: RootScopeService, private readonly windowRef: WindowRef) {
    this.isHosted = rootScopeService.isHosted;
  }

  private postMessage(data: WindowParentMessage, notHostedCallback: () => void): void {
    if (this.isHosted) {
      this.windowRef.nativeWindow.parent.postMessage(data, window.location.origin);
    } else if (notHostedCallback) {
      notHostedCallback();
    }
  }

  postLifeCycleMessage = (data: WindowParentMessage, notHostedCallback?: () => void): void => {
    this.postMessage({ ...data, type: MessageType.lifecycle }, notHostedCallback);
  };

  postNavigationMessage = (data: WindowParentMessage, notHostedCallback?: () => void): void => {
    this.postMessage({ ...data, type: MessageType.navigation }, notHostedCallback);
  };

  postAutosizeMessage = (data: WindowParentMessage, notHostedCallback?: () => void): void => {
    this.postMessage({ ...data, type: MessageType.autoSize }, notHostedCallback);
  };

  postRequestForData = <T>(key: string, hostId: string, component: { onRequestDataResponseReceived: { [key: string]: (data: { value: T }) => void } }, appsCallback: () => Promise<T>): Promise<T> => {
    if (!this.isHosted) {
      return appsCallback();
    }

    return new Promise((resolve) => {
      component.onRequestDataResponseReceived[key] = (data) => {
        component.onRequestDataResponseReceived[key] = null;
        resolve(data.value);
      };
      this.postLifeCycleMessage({
        action: 'onRequestData',
        payload: key,
        target: hostId
      });
    });
  };
}

export class WindowParentMessage {
  type?: MessageType;
  args?: Array<any>;
  action?: string;
  target?: string;
  height?: number;
  payload?: any;
}

export enum MessageType {
  lifecycle = 'L',
  navigation = 'N',
  autoSize = 'A'
}
