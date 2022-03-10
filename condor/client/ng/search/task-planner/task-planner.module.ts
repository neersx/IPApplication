import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { CasesCoreModule } from 'cases/core/cases.core.module';
import { DatesModule } from 'dates/dates.module';
import { FinaliseAdHocDateComponent } from 'dates/finalise-adhoc-date.component';
import { SharedModule } from 'shared/shared.module';
import {
  EventNoteDetailsModule
} from '../../portfolio/event-note-details/event-note-details.module';
import { CaseSummaryComponent } from './case-summary/case-summary.component';
import { CaseSummaryService } from './case-summary/case-summary.service';
import {
  DeferReminderToDateModalComponent
} from './defer-reminder-date-modal/defer-reminder-to-date-modal.component';
import {
  DueDateResponsibilityModalComponent
} from './due-date-responsibility-modal/due-date-responsibility-modal.component';
import {
  ForwardReminderModalComponent
} from './forward-reminder-modal/forward-reminder-modal.component';
import { ProvideInstructionsModalComponent } from './provide-instructions-modal/provide-instructions-modal.component';
import { ProvideInstructionsService } from './provide-instructions-modal/provide-instructions.service';
import { ReminderActionProvider } from './reminder-action.provider';
import { SendEmailModalComponent } from './send-email-modal/send-email-modal.component';
import { TaskPlannerDetailComponent } from './task-planner-details/task-planner-detail';
import {
  TaskPlannerReminderCommentsComponent
} from './task-planner-details/task-planner-reminder-comments';
import { TaskPlannerPersistenceService } from './task-planner-persistence.service';
import { SearchBuilderState, TaskPlannerState } from './task-planner-routing.states';
import {
  AdhocDateSearchBuilderComponent
} from './task-planner-search-builder/adhoc-date-search-builder/adhoc-date-search-builder.component';
import {
  CasesCriteriaSearchBuilderComponent
} from './task-planner-search-builder/cases-criteria-search-builder/cases-criteria-search-builder.component';
import {
  EventsActionsSearchBuilderComponent
} from './task-planner-search-builder/events-actions-search-builder/events-actions-search-builder.component';
import {
  GeneralSearchBuilderComponent
} from './task-planner-search-builder/general-search-builder/general-search-builder.component';
import {
  RemindersSearchBuilderComponent
} from './task-planner-search-builder/reminders-search-builder/reminders-search-builder.component';
import {
  TaskPlannerSearchBuilderComponent
} from './task-planner-search-builder/task-planner-search-builder.component';
import {
  TaskPlannerSearchResultComponent
} from './task-planner-search-result/task-planner-search-result.component';
import {
  TaskPlannerSearchHelperService
} from './task-planner-search-result/task-planner-search.helper.service';
import {
  TaskPlannerSerachResultFilterService
} from './task-planner-search-result/task-planner.filter.service';
import { TaskPlannerComponent } from './task-planner.component';
import { TaskPlannerService } from './task-planner.service';

export let routeStates = [TaskPlannerState, SearchBuilderState];
@NgModule({
  imports: [
    CommonModule,
    UIRouterModule.forChild({ states: routeStates }),
    SharedModule,
    CasesCoreModule,
    EventNoteDetailsModule,
    DatesModule
  ],
  declarations: [
    TaskPlannerComponent,
    TaskPlannerSearchResultComponent,
    TaskPlannerSearchBuilderComponent,
    GeneralSearchBuilderComponent,
    EventsActionsSearchBuilderComponent,
    RemindersSearchBuilderComponent,
    CaseSummaryComponent,
    CasesCriteriaSearchBuilderComponent,
    TaskPlannerDetailComponent,
    TaskPlannerReminderCommentsComponent,
    AdhocDateSearchBuilderComponent,
    DeferReminderToDateModalComponent,
    DueDateResponsibilityModalComponent,
    ForwardReminderModalComponent,
    SendEmailModalComponent,
    ProvideInstructionsModalComponent
  ],
  providers: [TaskPlannerService, ProvideInstructionsService, CaseSummaryService, TaskPlannerPersistenceService, TaskPlannerSerachResultFilterService, ReminderActionProvider, TaskPlannerSearchHelperService],
  entryComponents: [FinaliseAdHocDateComponent]
})
export class TaskPlannerModule { }