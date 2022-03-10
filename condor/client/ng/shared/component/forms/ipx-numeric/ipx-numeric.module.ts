import { NgModule } from '@angular/core';
import { NumericTextBoxModule } from '@progress/kendo-angular-inputs';
import { IntlModule } from '@progress/kendo-angular-intl';
import { BaseCommonModule } from 'shared/base.common.module';
import { IpxNumericComponent } from './ipx-numeric.component';

@NgModule({
    imports: [NumericTextBoxModule, IntlModule, BaseCommonModule],
    declarations: [IpxNumericComponent],
    exports: [IpxNumericComponent]
})
export class IpxNumericModule { }
