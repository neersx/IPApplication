import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from '../buttons/buttons.module';
import { ConfirmBeforePageChangeDirective } from './confirm-before-page-change.directive';
import { DetailPageNavComponent } from './detail-page-nav.component';
import { HostedPageHeaderComponent } from './hosted-page-header/hosted-page-header.component';
import { IpxLevelUpButtonComponent } from './ipx-level-up.component';
import { IpxStickyHeaderComponent } from './ipx-sticky-header/ipx-sticky-header.component';
import { LastSearchService } from './last-search.service';
import { PageHelperService } from './page-helper.service';
import { ActionButtonsComponent } from './title/action-buttons.component';
import { AfterTitleComponent } from './title/after-title.component';
import { BeforeButtonsComponent } from './title/before-buttons.component';
import { BeforeTitleComponent } from './title/before-title.component';
import { PageTitleSaveComponent } from './title/page-title-save.component';
import { PageTitleComponent } from './title/page-title.component';

@NgModule({
    imports: [
        ButtonsModule,
        UIRouterModule
    ],
    providers: [
        PageHelperService,
        LastSearchService
    ],
    declarations: [
        PageTitleComponent,
        BeforeTitleComponent,
        BeforeButtonsComponent,
        AfterTitleComponent,
        ActionButtonsComponent,
        PageTitleSaveComponent,
        DetailPageNavComponent,
        ConfirmBeforePageChangeDirective,
        IpxLevelUpButtonComponent,
        IpxStickyHeaderComponent,
        HostedPageHeaderComponent
    ],
    exports: [
        PageTitleComponent,
        BeforeTitleComponent,
        BeforeButtonsComponent,
        AfterTitleComponent,
        ActionButtonsComponent,
        PageTitleSaveComponent,
        DetailPageNavComponent,
        ConfirmBeforePageChangeDirective,
        IpxLevelUpButtonComponent,
        ButtonsModule,
        UIRouterModule,
        IpxStickyHeaderComponent,
        HostedPageHeaderComponent
    ]
})
export class PageModule { }
