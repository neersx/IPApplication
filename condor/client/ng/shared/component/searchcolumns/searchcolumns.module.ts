import { NgModule } from '@angular/core';
import { TranslateModule } from '@ngx-translate/core';
import { BaseCommonModule } from 'shared/base.common.module';
import { FormControlsModule } from 'shared/component/forms/form-controls.module';
import { TooltipModule } from '../tooltip/tooltip.module';
import { IpxBooleanColumnComponent } from './ipx-boolean-column/ipx-boolean-column.component';
import { IpxUserColumnUrlComponent } from './ipx-user-column-url/ipx-user-column-url.component';

@NgModule({
    imports: [
       BaseCommonModule,
       TranslateModule,
       TooltipModule,
       FormControlsModule
    ],
    declarations: [
        IpxBooleanColumnComponent,
        IpxUserColumnUrlComponent
    ],
    exports: [
        IpxBooleanColumnComponent,
        IpxUserColumnUrlComponent
    ]
 })
 export class SearchColumnsModule { }