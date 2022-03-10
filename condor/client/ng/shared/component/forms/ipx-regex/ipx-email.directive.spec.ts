import { Component, DebugElement } from '@angular/core';
import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { AbstractControl, FormsModule, NgForm } from '@angular/forms';
import { By } from '@angular/platform-browser';
import { TranslateFakeLoader, TranslateLoader, TranslateModule, TranslateService } from '@ngx-translate/core';
import { TranslationServiceMock } from 'ajs-upgraded-providers/mocks/translation-service.mock';
import { Translate } from 'ajs-upgraded-providers/translate.mock';
import { TranslationService } from 'ajs-upgraded-providers/translation.service.provider';

import { IpxEmailDirective } from './ipx-email.directive';
  describe('IpxRegexDirective', () => {
  @Component({
    template: `<form>
                  <input [(ngModel)]="testString" type="text" ipx-email name="testEmail">
              </form>`
  })
  class TestEmailComponent {
    testString: string;
  }

  let input: DebugElement;
  let debug: DebugElement;
  let fixture: ComponentFixture<TestEmailComponent>;
  let form: NgForm;
  let control: AbstractControl;
  beforeEach(() => {
    fixture = TestBed.configureTestingModule({
      imports: [
        TranslateModule.forRoot({
          loader: {
            provide: TranslateLoader,

            useClass: TranslateFakeLoader
          }
        }),
        FormsModule
      ],
      providers: [
        { provide: TranslationService, useValue: TranslationServiceMock },
        TranslateService
      ],
      declarations: [TestEmailComponent, IpxEmailDirective, Translate]
    }).createComponent(TestEmailComponent);
    fixture.detectChanges();
    debug = fixture.debugElement;
    form = debug.children[0].injector.get(NgForm);
  });

  it('should create', () => {
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should fail validation for an invalid email (No @ Symbol)', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      control = form.control.get('testEmail');
      input = debug.query(By.css('input'));
      input.nativeElement.value = 'failedEmail';
      input.nativeElement.dispatchEvent(new Event('input'));
      expect(control.hasError('regex')).toBe(true);
      expect(form.control.valid).toEqual(false);
    });
  }));

  it('should fail validation for an invalid email (No top level domain)', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      control = form.control.get('testEmail');
      input = debug.query(By.css('input'));
      input.nativeElement.value = 'failedEmail@testdomain';
      input.nativeElement.dispatchEvent(new Event('input'));
      expect(control.hasError('regex')).toBe(true);
      expect(form.control.valid).toEqual(false);
    });
  }));

  it('should fail validation for an invalid email (No domain before top level domain)', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      control = form.control.get('testEmail');
      input = debug.query(By.css('input'));
      input.nativeElement.value = 'failedEmail@.com';
      input.nativeElement.dispatchEvent(new Event('input'));
      expect(control.hasError('regex')).toBe(true);
      expect(form.control.valid).toEqual(false);
    });
  }));

  it('should fail validation for an invalid email (single character top level domain)', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      control = form.control.get('testEmail');
      input = debug.query(By.css('input'));
      input.nativeElement.value = 'failedEmail@test.c';
      input.nativeElement.dispatchEvent(new Event('input'));
      expect(control.hasError('regex')).toBe(true);
      expect(form.control.valid).toEqual(false);
    });
  }));

  it('should fail validation for an invalid email (more than 4 characters top level domain)', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      control = form.control.get('testEmail');
      input = debug.query(By.css('input'));
      input.nativeElement.value = 'failedEmail@test.tester';
      input.nativeElement.dispatchEvent(new Event('input'));
      expect(control.hasError('regex')).toBe(true);
      expect(form.control.valid).toEqual(false);
    });
  }));

  it('should fail validation for an invalid email (numbers in top level domain)', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      control = form.control.get('testEmail');
      input = debug.query(By.css('input'));
      input.nativeElement.value = 'failedEmail@test.123';
      input.nativeElement.dispatchEvent(new Event('input'));
      expect(control.hasError('regex')).toBe(true);
      expect(form.control.valid).toEqual(false);
    });
  }));

  it('should fail validation for an invalid email (multiple @ symbols)', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      control = form.control.get('testEmail');
      input = debug.query(By.css('input'));
      input.nativeElement.value = 'failed@Email@test.com';
      input.nativeElement.dispatchEvent(new Event('input'));
      expect(control.hasError('regex')).toBe(true);
      expect(form.control.valid).toEqual(false);
    });
  }));

  it('should succeed validation for a valid email', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      control = form.control.get('testEmail');
      input = debug.query(By.css('input'));
      input.nativeElement.value = 'test@testdomain.com';
      input.nativeElement.dispatchEvent(new Event('input'));
      fixture.detectChanges();
      expect(control.hasError('regex')).toBe(false);
      expect(form.control.valid).toEqual(true);
    });
  }));

  it('should succeed validation for a valid email(allows numbers in the domain', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      control = form.control.get('testEmail');
      input = debug.query(By.css('input'));
      input.nativeElement.value = 'test@44222.com';
      input.nativeElement.dispatchEvent(new Event('input'));
      fixture.detectChanges();
      expect(control.hasError('regex')).toBe(false);
      expect(form.control.valid).toEqual(true);
    });
  }));

  it('should succeed validation for a valid email(allows single character domain', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      control = form.control.get('testEmail');
      input = debug.query(By.css('input'));
      input.nativeElement.value = 'test@t.com';
      input.nativeElement.dispatchEvent(new Event('input'));
      fixture.detectChanges();
      expect(control.hasError('regex')).toBe(false);
      expect(form.control.valid).toEqual(true);
    });
  }));
});
