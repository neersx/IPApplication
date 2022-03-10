import { NgModule } from '@angular/core';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { TranslateModule } from '@ngx-translate/core';
import { ColorPickerModule } from '@progress/kendo-angular-inputs';
import { CodemirrorModule } from 'ng2-codemirror';
import { QuillModule } from 'ngx-quill';
import { BaseCommonModule } from 'shared/base.common.module';
import { PipesModule } from 'shared/pipes/pipes.module';
import { AutoFocusDirective } from '../focus';
import { TooltipModule } from '../tooltip/tooltip.module';
import { ButtonsModule } from './../buttons/buttons.module';
import { ElementBaseComponent } from './element-base.component';
import { FormControlHelperService } from './form-control-helper.service';
import { IpxCheckboxComponent } from './ipx-checkbox/ipx-checkbox.component';
import { IpxClockComponent } from './ipx-clock/ipx-clock.component';
import { IpxColorPickerComponent } from './ipx-color-picker/ipx-color-picker.component';
import { IpxCurrencyComponent } from './ipx-currency/ipx-currency.component';
import { IpxDatePickerModule } from './ipx-date-picker/ipx-date-picker.module';
import { IpxDateTimeComponent } from './ipx-date-time/ipx-date-time.component';
import { IpxDateComponent } from './ipx-date/ipx-date.component';
import { IpxdebtorStatusIconComponent } from './ipx-debtor-status-icon/ipx-debtor-status-icon.component';
import { IpxDropdownOperatorComponent } from './ipx-dropdown-operator/ipx-dropdown-operator.component';
import { IpxDropdownComponent } from './ipx-dropdown/ipx-dropdown.component';
import { IpxEmailLinkComponent } from './ipx-email-link/ipx-email-link.component';
import { HeaderComponent } from './ipx-header/ipx-header.component';
import { IpxHostedUrlComponent } from './ipx-hosted-url/ipx-hosted-url.component';
import { IpxIeOnlyUrlModule } from './ipx-ie-only-url/ipx-ie-only-url.module';
import { InputRefDirective } from './ipx-inputref.directive ';
import { IpxMultiStateCheckboxComponent } from './ipx-multistate-checkbox/ipx-multistate-checkbox.component';
import { IpxNumericModule } from './ipx-numeric/ipx-numeric.module';
import { IpxRadioButtonGroupComponent } from './ipx-radio-button-group/ipx-radio-button-group.component';
import { IpxRadioButtonComponent } from './ipx-radio-button/ipx-radio-button.component';
import { IpxRichtextFieldComponent } from './ipx-richtext-field/ipx-richtext-field/ipx-richtext-field.component';
import { SearchOptionComponent } from './ipx-search-option/ipx-search-option.component';
import { IpxTextDropdownGroupComponent } from './ipx-text-dropdown-group/ipx-text-dropdown-group.component';
import { IpxTextFieldComponent } from './ipx-text-field/ipx-text-field.component';
import { IpxTextareaComponent } from './ipx-textarea/ipx-textarea.component';
import { IpxTimePickerModule } from './ipx-time-picker/ipx-time-picker.module';
import { OneTimeBindComponent } from './one-time-bind.component';
import { WizardComponentHostDirective } from './wizard-navigation/wizard-component-host.directive';
import { WizardNavigationComponent } from './wizard-navigation/wizard-navigation.component';
const standaloneComponents = [OneTimeBindComponent];
const formCommonControls = [
   ElementBaseComponent,
   IpxCheckboxComponent,
   IpxDateComponent,
   IpxDateTimeComponent,
   IpxClockComponent,
   IpxDropdownComponent,
   IpxDropdownOperatorComponent,
   IpxRadioButtonComponent,
   IpxRadioButtonGroupComponent,
   IpxTextareaComponent,
   IpxTextDropdownGroupComponent,
   IpxTextFieldComponent,
   IpxEmailLinkComponent,
   WizardNavigationComponent,
   IpxRichtextFieldComponent,
   IpxCurrencyComponent,
   IpxdebtorStatusIconComponent,
   SearchOptionComponent,
   HeaderComponent,
   IpxColorPickerComponent,
   IpxMultiStateCheckboxComponent
];
const hostComponents = [IpxHostedUrlComponent];

const directives = [
   AutoFocusDirective,
   WizardComponentHostDirective,
   InputRefDirective
];

@NgModule({
   imports: [
      BaseCommonModule,
      BrowserAnimationsModule,
      TranslateModule,
      TooltipModule,
      QuillModule.forRoot(),
      PipesModule,
      ButtonsModule,
      CodemirrorModule,
      ColorPickerModule
   ],
   declarations: [
      ...directives,
      ...standaloneComponents,
      ...formCommonControls,
      ...hostComponents
   ],
   exports: [
      IpxDatePickerModule,
      IpxIeOnlyUrlModule,
      IpxTimePickerModule,
      IpxNumericModule,
      ...directives,
      ...standaloneComponents,
      ...formCommonControls,
      ...hostComponents
   ],
   providers: [
      FormControlHelperService
   ]
})
export class FormControlsModule { }
