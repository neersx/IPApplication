import { async } from '@angular/core/testing';
import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import { WindowParentMessagingService } from './window-parent-messaging.service';
import { WindowRefMock } from './window-ref.mock';

describe('Service: WindowParentMessaging', () => {
  let service: WindowParentMessagingService;
  let windowRefMock: WindowRefMock;
  beforeEach(() => {
    windowRefMock = new WindowRefMock();
    service = new WindowParentMessagingService(new RootScopeServiceMock() as any, windowRefMock as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('postAutosizeMessage', () => {
    it('should call callback if not hosted', () => {
      const callback = jest.fn();
      service.isHosted = false;

      service.postAutosizeMessage({}, callback);

      expect(windowRefMock.nativeWindow.parent.postMessage).not.toHaveBeenCalled();
      expect(callback).toHaveBeenCalled();
    });

    it('should not call callback if hosted', () => {
      const callback = jest.fn();
      service.isHosted = true;

      service.postAutosizeMessage({}, callback);

      expect(windowRefMock.nativeWindow.parent.postMessage).toHaveBeenCalled();
      expect(callback).not.toHaveBeenCalled();
    });
  });

  describe('postLifeCycleMessage', () => {
    it('should call callback if not hosted', () => {
      const callback = jest.fn();
      service.isHosted = false;

      service.postLifeCycleMessage({}, callback);

      expect(windowRefMock.nativeWindow.parent.postMessage).not.toHaveBeenCalled();
      expect(callback).toHaveBeenCalled();
    });

    it('should not call callback if hosted', () => {
      const callback = jest.fn();
      service.isHosted = true;

      service.postLifeCycleMessage({}, callback);

      expect(callback).not.toHaveBeenCalled();
      expect(windowRefMock.nativeWindow.parent.postMessage).toHaveBeenCalled();
    });
  });

  describe('postNavigationMessage', () => {
    it('should call callback if not hosted', () => {
      const callback = jest.fn();
      service.isHosted = false;

      service.postNavigationMessage({}, callback);

      expect(windowRefMock.nativeWindow.parent.postMessage).not.toHaveBeenCalled();
      expect(callback).toHaveBeenCalled();
    });

    it('should not call callback if hosted', () => {
      const callback = jest.fn();
      service.isHosted = true;

      service.postNavigationMessage({}, callback);

      expect(windowRefMock.nativeWindow.parent.postMessage).toHaveBeenCalled();
      expect(callback).not.toHaveBeenCalled();
    });
  });

  describe('postRequestForData', () => {
    it('should call appsCallback if not hosted', () => {
      const callback = jest.fn().mockReturnValue('test');
      service.isHosted = false;

      const returnValue = service.postRequestForData('key', 'hostId', { onRequestDataResponseReceived: {} as any }, callback);

      expect(callback).toHaveBeenCalled();
      expect(returnValue).toEqual('test');
    });

    it('should return a promise that resolves on the callback being called', async(() => {
      const callback = jest.fn().mockReturnValue('test');
      service.isHosted = true;

      const component = { onRequestDataResponseReceived: {} as any };
      const returnedPromise = service.postRequestForData('key1', 'hostId', component, callback);
      const returnedPromise2 = service.postRequestForData('key2', 'hostId', component, callback);
      component.onRequestDataResponseReceived.key1({value: 'test'});
      component.onRequestDataResponseReceived.key2({value: 'test2'});

      expect(callback).not.toHaveBeenCalled();

      returnedPromise.then(value => {
        expect(value).toEqual('test');
      });
      returnedPromise2.then(value => {
        expect(value).toEqual('test2');
      });
    }));
  });
});
