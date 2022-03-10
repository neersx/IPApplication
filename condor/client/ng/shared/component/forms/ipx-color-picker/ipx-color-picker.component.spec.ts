import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { ColorPickerModule } from '@progress/kendo-angular-inputs';
import { TranslatedServiceMock, TranslatePipeMock } from '../../../../../signin/src/app/mock/index.spec';
import { Translate } from '../../../../ajs-upgraded-providers/translate.mock';
import { IpxColorPickerComponent } from './ipx-color-picker.component';

describe('IpxColorPickerComponent', () => {
  let component: IpxColorPickerComponent;
  let fixture: ComponentFixture<IpxColorPickerComponent>;

  const translate: TranslatedServiceMock = new TranslatedServiceMock();
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        FormsModule,
        TranslateModule,
        ColorPickerModule
      ],
      providers: [{ provide: TranslateService, useValue: translate }],
      declarations: [IpxColorPickerComponent, Translate, TranslatePipeMock]
    });
    fixture = TestBed.createComponent(IpxColorPickerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });
  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('initialize default component', () => {
    const settings = {
      palette: [
        null, '#fff2ac', '#fae71d', '#ffb171',
        '#ffcce5', '#ceb5e5', '#e5e5e5', '#cdeaff',
        '#cbf1c5', '#b9d87b', '#e3c0b4', '#fd6963'
      ],
      columns: 6,
      tileSize: 30
    };
    component.ngOnInit();
    expect(component.settings).not.toBeUndefined();
    expect(component.settings).toEqual(settings);
  });

  it('initialize component with custom settings', () => {
    const customSettings = {
      palette: [
        '#ef8f8f', '#e4e3e3', '#cefc8e', '#a0f5df'
      ],
      columns: 2,
      tileSize: 20
    };
    component.settings = customSettings;
    component.ngOnInit();
    expect(component.settings).toBe(customSettings);
  });

  it('should update changed value', () => {
    const newValue = '#e4e3e3';
    jest.spyOn(component.onChange, 'emit');
    component.change(newValue);
    expect(component.value).toBe(newValue);
    expect(component.onChange.emit).toBeCalledWith(newValue);
  });
});
