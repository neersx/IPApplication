
import { NgModule } from '@angular/core';
import { SharedModule } from 'shared/shared.module';
import { DatesLogicComponent } from './dates-logic.component';
import { DueDateCalculationInformationComponent } from './duedate-information.component';
import { EventDocumentsComponent } from './event-documents.component';
import { EventInformationComponent } from './event-information.component';
import { EventOtherDetailsComponent } from './event-other-details.controller';
import { EventRemindersComponent } from './event-reminders.component';
import { EventRuleDetailsService } from './event-rule-details.service';
import { EventRulesComponent } from './event-rules.component';
import { EventUpdateInfoComponent } from './event-update-info.component';

const components = [
    EventRulesComponent,
    EventInformationComponent,
    DueDateCalculationInformationComponent,
    EventRemindersComponent,
    DatesLogicComponent,
    EventDocumentsComponent,
    EventUpdateInfoComponent,
    EventOtherDetailsComponent];
@NgModule({
    imports: [
        SharedModule
    ],
    exports: [
        ...components
    ],
    declarations: [
        ...components
    ],
    providers: [EventRuleDetailsService],
    entryComponents: [
        ...components
    ]
})
export class EventRuleDetailsModule { }
