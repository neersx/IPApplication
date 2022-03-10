
import { ChangeDetectionStrategy, Component, ViewChild } from '@angular/core';
import { async, fakeAsync, TestBed, tick } from '@angular/core/testing';
import { FormBuilder, FormGroup, FormsModule, NgModel, ReactiveFormsModule } from '@angular/forms';
import { Translate } from '../../../../ajs-upgraded-providers/translate.mock';
import { IpxRadioButtonComponent } from '../ipx-radio-button/ipx-radio-button.component';
import { IpxRadioButtonGroupComponent } from './ipx-radio-button-group.component';

@Component({
  template: `<ipx-radio-button-group #radioGroup name="radioGroup" value="Baz" required="true">
  <ipx-radio-button *ngFor="let item of ['Foo', 'Bar', 'Baz']; trackBy: item;" value="{{ item }}">
      {{ item }}      </ipx-radio-button> </ipx-radio-button-group>`,
  changeDetection: ChangeDetectionStrategy.OnPush
})
class RadioGroupComponent {
  @ViewChild('radioGroup', { read: IpxRadioButtonGroupComponent, static: true }) radioGroup: IpxRadioButtonGroupComponent;
}

class RadioOption {
  name: string;
  favoriteOption: string;
}

@Component({
  template: `<form [formGroup]="optionForm">  <ipx-radio-button-group formControlName="favoriteOption" name="radioGroupReactive">
      <ipx-radio-button *ngFor="let item of options; trackBy: item" value="{{ item }}">          {{ item }}
      </ipx-radio-button>  </ipx-radio-button-group> </form>`,
  changeDetection: ChangeDetectionStrategy.OnPush
})
class RadioGroupReactiveFormsComponent {
  options = [
    'Option1',
    'Option2',
    'Option3',
    'Option4'
  ];

  newModel: RadioOption;
  model: RadioOption = { name: 'Inprotech', favoriteOption: this.options[1] };
  optionForm: FormGroup;

  constructor(private readonly _formBuilder: FormBuilder) {
    this._createForm();
  }

  updateModel(): any {
    const formModel = this.optionForm.value;

    this.newModel = {
      name: formModel.name as string,
      favoriteOption: formModel.favoriteOption as string
    };
  }

  private _createForm(): any {
    this.optionForm = this._formBuilder.group({
      name: '',
      favoriteOption: ''
    });

    this.optionForm.setValue({
      name: this.model.name,
      favoriteOption: this.model.favoriteOption
    });
  }
}

describe('IpxRadioButtonGroupComponent', () => {

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [FormsModule, ReactiveFormsModule],
      declarations: [
        IpxRadioButtonGroupComponent,
        IpxRadioButtonComponent,
        RadioGroupReactiveFormsComponent,
        RadioGroupComponent,
        Translate],
      providers: [NgModel]
    })
      .compileComponents();
  }));

  it('Properly initialize the radio group buttons\' properties.', fakeAsync(() => {
    const fixture = TestBed.createComponent(RadioGroupComponent);
    const radioInstance = fixture.componentInstance.radioGroup;

    fixture.detectChanges();
    tick();

    expect(radioInstance.radioButtons).toBeDefined();
    expect(radioInstance.radioButtons.length).toEqual(3);

    const allButtonsWithGroupName = radioInstance.radioButtons.filter((btn) => btn.name === radioInstance.name);
    expect(allButtonsWithGroupName.length).toEqual(radioInstance.radioButtons.length);

    const buttonWithGroupValue = radioInstance.radioButtons.find((btn) => btn.value === radioInstance.value);
    expect(buttonWithGroupValue).toBeDefined();
    expect(buttonWithGroupValue).toEqual(radioInstance.selected);
  }));

  it('Properly update the model when radio group is hosted in Reactive forms.', fakeAsync(() => {
    const fixture = TestBed.createComponent(RadioGroupReactiveFormsComponent);

    fixture.detectChanges();
    tick();

    expect(fixture.componentInstance.optionForm).toBeDefined();
    expect(fixture.componentInstance.model).toBeDefined();
    expect(fixture.componentInstance.newModel).toBeUndefined();

    fixture.componentInstance.optionForm.patchValue({ favoriteOption: fixture.componentInstance.options[0] });
    fixture.componentInstance.updateModel();
    fixture.detectChanges();
    tick();

    expect(fixture.componentInstance.newModel).toBeDefined();
    expect(fixture.componentInstance.newModel.name).toEqual(fixture.componentInstance.model.name);
    expect(fixture.componentInstance.newModel.favoriteOption).toEqual(fixture.componentInstance.options[0]);
  }));

});
