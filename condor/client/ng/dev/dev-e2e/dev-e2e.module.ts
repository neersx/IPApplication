import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { UIRouterModule } from '@uirouter/angular';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { QRCodeModule } from 'angularx-qrcode';
import { AppContextService } from 'core/app-context.service';
import { FormControlsModule } from 'shared/component/forms/form-controls.module';
import { SharedModule } from 'shared/shared.module';
import { DatePickerE2eComponent } from './date-picker.e2e/date-picker.component.e2e';
import { datePickerE2eState, formValidationState, hostedTestState, picklistState, qrCodeState } from './dev-e2e.states';
import { FormValidationComponent } from './form-validation/form-validation.component';
import { HostedTestComponent } from './hosted/hosted-test/hosted-test.component';
import { IpxPicklistE2eComponent } from './ipx-picklist/ipx-picklist.component';
import { QRCodeTestComponent } from './qrcodetest/qrcodetest.component';

export let routeStates = [datePickerE2eState, qrCodeState, formValidationState, picklistState, hostedTestState];

@NgModule({
  declarations: [
    DatePickerE2eComponent,
    QRCodeTestComponent,
    FormValidationComponent,
    IpxPicklistE2eComponent,
    HostedTestComponent
  ],
  imports: [
    FormsModule,
    FormControlsModule,
    SharedModule,
    QRCodeModule,
    UIRouterModule.forChild({ states: routeStates })
  ]
})
export class DevE2eModule {
  constructor(private readonly appContextService: AppContextService) {
    appContextService.isE2e = true;
  }
}
