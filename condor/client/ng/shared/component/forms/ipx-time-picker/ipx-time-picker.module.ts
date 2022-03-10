import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { DateInputsModule, TimePickerModule } from '@progress/kendo-angular-dateinputs';
import { IntlModule } from '@progress/kendo-angular-intl';
import { BaseCommonModule } from 'shared/base.common.module';
import { IpxTimePickerComponent } from './ipx-time-picker.component';

@NgModule({
    imports: [TimePickerModule, IntlModule, BaseCommonModule, HttpClientModule, DateInputsModule],
    declarations: [IpxTimePickerComponent],
    exports: [IpxTimePickerComponent, TimePickerModule, DateInputsModule]
})
export class IpxTimePickerModule { }
