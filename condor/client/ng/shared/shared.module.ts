import { ModuleWithProviders, NgModule } from '@angular/core';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { DatePickerDirective } from 'ajs-upgraded-providers/ajs-control-providers/date-picker-directive';
import { KendoGridDirective } from 'ajs-upgraded-providers/directives/kendo.directive.provider';
import { ResizeHandlerDirective } from 'ajs-upgraded-providers/directives/resize-handler.provider';
import { QRCodeModule } from 'angularx-qrcode';
import { NamesModule } from 'names/names.module';
import { ModalModule } from 'ngx-bootstrap/modal';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { EventCategoryIconService } from 'shared/shared-services/event-category-icon.service';
import { BaseCommonModule } from './base.common.module';
import { FocusService } from './component/focus';
import { FormControlsModule } from './component/forms/form-controls.module';
import { ImageFullComponent } from './component/forms/image/image-full.component';
import { ImageModule } from './component/forms/image/image.module';
import { DataTypeDirective } from './component/forms/ipx-data-type/ipx-data-type.directive';
import { IpxEmailDirective } from './component/forms/ipx-regex/ipx-email.directive';
import { GroupItemsComponent } from './component/grid/grouping/ipx-group-items.component';
import { GroupDetailComponent } from './component/grid/grouping/ipx-group.detail.component';
import { GroupHeaderItemComponent } from './component/grid/grouping/ipx-group.header.item.component';
import { IpxKendoGridModule } from './component/grid/ipx-kendo-grid.module';
import { IpxIframeComponent } from './component/iframe/ipx-iframe.component';
import { IpxModalService } from './component/modal/modal.service';
import { NotificationModule } from './component/notification/notification.module';
import { PageModule } from './component/page/page.module';
import { SearchColumnsModule } from './component/searchcolumns/searchcolumns.module';
import { IpxTabsModule } from './component/tabs/tabs.module';
import { TooltipModule } from './component/tooltip/tooltip.module';
import { TopicsModule } from './component/topics/topics.module';
import { IpxTypeaheadModule } from './component/typeahead/typeahead.module';
import { UtilityModule } from './component/utility/utility.module';
import { DirectivesModule } from './directives/directives.module';
import { PipesModule } from './pipes/pipes.module';
import { FileDownloadService } from './shared-services/file-download.service';
import { PropertyIconService } from './shared-services/property-icon.service';
import { WidgetModule } from './widget/widget.module';

const directives = [
    DatePickerDirective,
    KendoGridDirective,
    ResizeHandlerDirective,
    DataTypeDirective,
    IpxEmailDirective
];

@NgModule({
    imports: [
        BaseCommonModule,
        QRCodeModule,
        PageModule,
        TooltipModule,
        PopoverModule,
        IpxKendoGridModule,
        IpxTypeaheadModule,
        PipesModule,
        BrowserAnimationsModule,
        TopicsModule,
        PipesModule,
        DirectivesModule,
        FormControlsModule,
        SearchColumnsModule,
        ImageModule,
        UtilityModule,
        NamesModule,
        WidgetModule,
        IpxTabsModule,
        ModalModule.forRoot()
    ],
    declarations: [
        ...directives,
        IpxIframeComponent, GroupItemsComponent, GroupDetailComponent, GroupHeaderItemComponent
    ],
    entryComponents: [ImageFullComponent],
    exports: [
        BaseCommonModule,
        PipesModule,
        WidgetModule,
        IpxKendoGridModule,
        IpxTypeaheadModule,
        PageModule,
        FormControlsModule,
        SearchColumnsModule,
        ImageModule,
        NotificationModule,
        TopicsModule,
        TooltipModule,
        UtilityModule,
        ...directives,
        DirectivesModule,
        IpxTabsModule,
        IpxIframeComponent,
        GroupItemsComponent, GroupDetailComponent, GroupHeaderItemComponent
    ],
    providers: [
        FocusService,
        IpxModalService,
        PropertyIconService,
        EventCategoryIconService,
        FileDownloadService
    ]
})
export class SharedModule {
    static forRoot(): ModuleWithProviders<SharedModule> {
        return {
            ngModule: SharedModule,
            providers: [
                PropertyIconService,
                EventCategoryIconService,
                FileDownloadService
            ]
        };
    }
}