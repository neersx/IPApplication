import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';
import { ContextMenuModule } from '@progress/kendo-angular-menu';
import { UIRouterModule } from '@uirouter/angular';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { AddButtonComponent, AdvancedSearchButtonComponent, ApplyButtonComponent, ClearButtonComponent, CloseButtonComponent, DeleteButtonComponent, EditButtonComponent, HistoryButtonComponent, IconButtonComponent, PreviewButtonComponent, RevertButtonComponent, SaveButtonComponent, StepButtonComponent } from './buttons.component';
import { ContextMenuButtonComponent } from './context-menu-button.component';
import { IconComponent } from './icon.component';
import { NavigateStateButtonComponent } from './navigate-state-button.component';

@NgModule({
    imports: [
        CommonModule,
        FormsModule,
        TranslateModule,
        TooltipModule,
        ContextMenuModule,
        UIRouterModule
    ],
    declarations: [
        AddButtonComponent,
        ApplyButtonComponent,
        ClearButtonComponent,
        CloseButtonComponent,
        IconButtonComponent,
        PreviewButtonComponent,
        RevertButtonComponent,
        StepButtonComponent,
        SaveButtonComponent,
        AdvancedSearchButtonComponent,
        IconComponent,
        DeleteButtonComponent,
        EditButtonComponent,
        ContextMenuButtonComponent,
        HistoryButtonComponent,
        NavigateStateButtonComponent
    ],
    exports: [
        AddButtonComponent,
        ApplyButtonComponent,
        ClearButtonComponent,
        CloseButtonComponent,
        IconButtonComponent,
        PreviewButtonComponent,
        RevertButtonComponent,
        StepButtonComponent,
        SaveButtonComponent,
        AdvancedSearchButtonComponent,
        IconComponent,
        CommonModule,
        TranslateModule,
        TooltipModule,
        DeleteButtonComponent,
        EditButtonComponent,
        ContextMenuButtonComponent,
        HistoryButtonComponent,
        NavigateStateButtonComponent
    ]
})
export class ButtonsModule { }