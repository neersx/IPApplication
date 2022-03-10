import { NgModule } from '@angular/core';
import { LayoutModule } from '@progress/kendo-angular-layout';
import { BaseCommonModule } from 'shared/base.common.module';
import { IpxEventCategoryIconComponent, IpxPropertyTypeIconComponent } from '.';
import { TypeDecorator } from './type.decorator';

@NgModule({
    imports: [BaseCommonModule,
    LayoutModule],
    declarations: [
        IpxPropertyTypeIconComponent,
        IpxEventCategoryIconComponent
    ],
    exports: [
        IpxPropertyTypeIconComponent,
        IpxEventCategoryIconComponent,
        LayoutModule
    ]

})
export class UtilityModule { }