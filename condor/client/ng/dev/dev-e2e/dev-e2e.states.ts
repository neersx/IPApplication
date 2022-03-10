import { Ng2StateDeclaration } from '@uirouter/angular';
import { DatePickerE2eComponent } from './date-picker.e2e/date-picker.component.e2e';
import { FormValidationComponent } from './form-validation/form-validation.component';
import { HostedTestComponent } from './hosted/hosted-test/hosted-test.component';
import { IpxPicklistE2eComponent } from './ipx-picklist/ipx-picklist.component';
import { QRCodeTestComponent } from './qrcodetest/qrcodetest.component';

export const datePickerE2eState: Ng2StateDeclaration = {
    name: 'ngdatepickere2e',
    url: '/deve2e/ngdatepicker',
    component: DatePickerE2eComponent
};

export const qrCodeState: Ng2StateDeclaration = {
    name: 'qrcodeExample',
    url: '/dev/qrcode',
    component: QRCodeTestComponent
};

export const formValidationState: Ng2StateDeclaration = {
    name: 'formValidation',
    url: '/deve2e/formvalidation',
    component: FormValidationComponent
};

export const picklistState: Ng2StateDeclaration = {
    name: 'picklist',
    url: '/deve2e/ipx-picklist',
    component: IpxPicklistE2eComponent
};

export const hostedTestState: Ng2StateDeclaration = {
    name: 'e2eHosted',
    url: '/deve2e/hosted-test',
    component: HostedTestComponent
};