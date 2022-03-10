import { NgModule } from '@angular/core';
import { TranslateModule } from '@ngx-translate/core';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { BaseCommonModule } from './../../base.common.module';
import { IpxHoverHelpComponent } from './ipx-hover-help/ipx-hover-help.component';
import { IpxInlineDialogComponent } from './ipx-inline-dialog/ipx-inline-dialog.component';

@NgModule({
    imports: [
        BaseCommonModule,
        PopoverModule,
        TranslateModule
    ],
    declarations: [
        IpxInlineDialogComponent,
        IpxHoverHelpComponent
    ],
    exports: [
        BaseCommonModule,
        IpxInlineDialogComponent,
        IpxHoverHelpComponent
    ]
})

export class TooltipModule { }