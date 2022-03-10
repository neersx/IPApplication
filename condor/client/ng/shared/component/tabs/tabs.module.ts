import { NgModule } from '@angular/core';
import { TranslateModule } from '@ngx-translate/core';
import { BaseCommonModule } from 'shared/base.common.module';
import { TemplateTabKeyDirective } from './tabs-key.directive';
import { IpxTabsComponent } from './tabs.component';

@NgModule({
    imports: [
        BaseCommonModule,
        TranslateModule
    ],
    declarations: [
        IpxTabsComponent,
        TemplateTabKeyDirective
    ],
    exports: [
        IpxTabsComponent,
        TemplateTabKeyDirective
    ]
})

export class IpxTabsModule { }