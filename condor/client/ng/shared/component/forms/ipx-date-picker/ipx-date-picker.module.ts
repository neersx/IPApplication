import { NgModule } from '@angular/core';
import { AjsUpgradedProviderModule } from 'ajs-upgraded-providers/ajs-upgraded-provider.module';
import { BsDatepickerModule } from 'ngx-bootstrap/datepicker';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { BaseCommonModule } from 'shared/base.common.module';
import { TooltipModule } from 'shared/component/tooltip/tooltip.module';
import { IpxDatePickerComponent } from './ipx-date-picker.component';

@NgModule({
    imports: [
        BaseCommonModule,
        TooltipModule,
        PopoverModule,
        AjsUpgradedProviderModule,
        BsDatepickerModule.forRoot()
      ],
    declarations: [
        IpxDatePickerComponent
    ],
    exports: [
        IpxDatePickerComponent
    ]
})
export class IpxDatePickerModule {

}
