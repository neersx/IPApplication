import { async } from '@angular/core/testing';

import { BsModalRefMock } from 'mocks';
import { IpxNotificationComponent } from './ipx-notification.component';

describe('NotificationComponent', () => {
  let component: IpxNotificationComponent;

  beforeEach(async(() => {
    component = new IpxNotificationComponent(new BsModalRefMock());
  }));

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should confirm', () => {
    component.confirm();
    component.confirmed$.subscribe((val) => {
      expect(val).toBe('confirm');
    });
  });

  it('should cancel', () => {
    component.confirm();
    component.cancelled$.subscribe((val) => {
      expect(val).toBe('cancel');
    });
  });
});
