import { ChangeDetectionStrategy, Component, ViewChild } from '@angular/core';
import { async, TestBed } from '@angular/core/testing';
import { FormsModule, NgModel } from '@angular/forms';
import { By } from '@angular/platform-browser';
import { Translate } from 'ajs-upgraded-providers/translate.mock';
import { IpxRadioButtonComponent } from './ipx-radio-button.component';

@Component({ template: ' <ipx-radio-button #radio>Radio </ipx-radio-button>',
changeDetection: ChangeDetectionStrategy.OnPush })
class InitRadioComponent {
  @ViewChild('radio', { static: true }) radio: IpxRadioButtonComponent;
}

describe('IpxRadioButtonComponent', () => {

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [FormsModule],
      declarations: [
        Translate,
        IpxRadioButtonComponent,
        InitRadioComponent],
      providers: [NgModel]
    })
      .compileComponents();
  }));

  it('Init a radio', () => {
    const fixture = TestBed.createComponent(IpxRadioButtonComponent);
    fixture.detectChanges();

    const nativeRadio = fixture.nativeElement;
    expect(nativeRadio).toBeTruthy();
  });

  it('Init a radio with id property', () => {
    const fixture1 = TestBed.createComponent(InitRadioComponent);
    fixture1.detectChanges();

    const radio = fixture1.componentInstance.radio;
    const domRadio = fixture1.debugElement.query(By.css('input')).nativeElement;

    expect(radio.id).toContain('ipx-radio-');
    expect(domRadio.id).toContain('ipx-radio-');

    radio.id = 'customRadio';
    fixture1.detectChanges();
    expect(radio.id).toBe('customRadio');

  });

});
