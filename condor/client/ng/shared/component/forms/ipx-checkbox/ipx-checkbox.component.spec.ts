import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { By } from '@angular/platform-browser';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { TranslatedServiceMock, TranslatePipeMock } from '../../../../../signin/src/app/mock/index.spec';
import { Translate } from '../../../../ajs-upgraded-providers/translate.mock';
import { IpxInlineDialogComponent } from '../../tooltip/ipx-inline-dialog/ipx-inline-dialog.component';
import { IpxCheckboxComponent } from './ipx-checkbox.component';

describe('IpxCheckboxComponent', () => {
  let component: IpxCheckboxComponent;
  let fixture: ComponentFixture<IpxCheckboxComponent>;
  let inputEl: any;

  const translate: TranslatedServiceMock = new TranslatedServiceMock();
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        FormsModule,
        PopoverModule.forRoot(),
        TranslateModule
       ],
       providers: [ { provide: TranslateService, useValue: translate } ],
      declarations: [IpxCheckboxComponent, IpxInlineDialogComponent, Translate, TranslatePipeMock]
    });
    fixture = TestBed.createComponent(IpxCheckboxComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
    inputEl = fixture.debugElement.query(By.css('input')).nativeElement;
  });

  it('should initialize', () => {
    expect(component).toBeTruthy();
  });

  it('check input states', () => {
    expect(inputEl.checked).toBeFalsy();

    inputEl.click();
    fixture.detectChanges();
    expect(inputEl.checked).toBeTruthy();
  });

});