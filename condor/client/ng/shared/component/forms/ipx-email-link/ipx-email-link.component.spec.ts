import { async } from '@angular/core/testing';
import { IpxEmailLinkComponent } from './ipx-email-link.component';
describe('IpxEmailLinkComponent', () => {
  let component: IpxEmailLinkComponent;
  beforeEach(async(() => {
    component = new IpxEmailLinkComponent();
  }));

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should check valid email', () => {
    component.email = null;
    expect(component).toBeTruthy();
    expect(component.isValid()).toBe(false);

    component.email = '';
    expect(component.isValid()).toBe(true);
  });

  it('should return right email to link', () => {
    const emaildata: any = {
      recipientEmail: 'abc@def.com',
      recipientCopiesTo: '',
      subject: 'Test subject',
      body: 'Hello world'
    };
    component.model = emaildata;
    expect(component.createUri(component.model)).toBe('mailto:abc@def.com?subject=Test%20subject&body=Hello%20world');
  });

  it('should configure email link with single cc recipients', () => {
    const emaildata: any = {
      recipientEmail: 'abc@def.com',
      recipientCopiesTo: ['one@two.com'],
      subject: 'Test subject',
      body: 'Hello world'
    };
    component.model = emaildata;
    expect(component.createUri(component.model)).toBe('mailto:abc@def.com?cc=one@two.com&subject=Test%20subject&body=Hello%20world');
  });

  it('should configure email link with multiple cc recipients', () => {
    const emaildata: any = {
      recipientEmail: 'abc@def.com',
      recipientCopiesTo: ['one@two.com', 'abc@xyz.com'],
      subject: 'Test subject',
      body: 'Hello world'
    };
    component.model = emaildata;
    expect(component.createUri(component.model)).toBe('mailto:abc@def.com?cc=one@two.com;abc@xyz.com&subject=Test%20subject&body=Hello%20world');
  });
});