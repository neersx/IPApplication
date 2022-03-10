import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { Transition, UIRouter, UIRouterModule } from '@uirouter/angular';
import { CaseviewUpgradedComponentsModule } from 'ajs-upgraded-providers/directives/caseview/caseview.module';
import { CasesCoreModule } from 'cases/core/cases.core.module';
import { AttachmentPopupService } from 'common/attachments/attachments-popup/attachment-popup.service';
import { CaseViewNameViewModule } from 'common/case-name/case-name.module';
import { AppContextService } from 'core/app-context.service';
import { PortfolioModule } from 'portfolio/portfolio.module';
import { KeepOnTopNotesViewService } from 'rightbarnav/keep-on-top-notes-view.service';
import { IpxKendoGridModule } from 'shared/component/grid/ipx-kendo-grid.module';
import { DirectivesModule } from 'shared/directives/directives.module';
import { PipesModule } from 'shared/pipes/pipes.module';
import { SharedModule } from 'shared/shared.module';
import { EventNoteDetailsModule } from './../../portfolio/event-note-details/event-note-details.module';
import { CaseviewActionEventComponent } from './actions/action-events.component';
import { CaseviewActionsComponent } from './actions/actions.component';
import { CaseViewActionsService } from './actions/case-view.actions.service';
import { AddAffectedCaseComponent } from './assignment-recordal/add-affected-case/add-affected-case.component';
import { AffectedCasesComponent } from './assignment-recordal/affected-cases.component';
import { AffectedCasesService } from './assignment-recordal/affected-cases.service';
import { AffectedCasesFilterMenuComponent } from './assignment-recordal/filter-menu/filter-menu.component';
import { RecordalStepElementControlsComponent } from './assignment-recordal/recordal-steps/recordal-step-elements-controls.component';
import { RecordalStepElementComponent } from './assignment-recordal/recordal-steps/recordal-step-elements.component';
import { RecordalStepsComponent } from './assignment-recordal/recordal-steps/recordal-steps.component';
import { RequestRecordalComponent } from './assignment-recordal/request-recordal/request-recordal.component';
import { AffectedCasesSetAgentComponent } from './assignment-recordal/set-agent/affected-cases-set-agent.component';
import { AffectedCasesSetAgentService } from './assignment-recordal/set-agent/affected-cases-set-agent.service';
import { CaseDetailService } from './case-detail.service';
import { CaseViewComponent } from './case-view.component';
import { caseViewState } from './case-view.states';
import { ChecklistsComponent } from './checklists/checklists.component';
import { RegenerateChecklistComponent } from './checklists/regeneration/regenerate-checklist';
import { CriticalDatesComponent } from './critical-dates/critical-dates.component';
import { CriticalDatesService } from './critical-dates/critical-dates.service';
import { CustomContentComponent } from './custom-content/custom-content.component';
import { DesignElementsMaintenanceComponent } from './design-elements/design-elements-maintenance/design-elements-maintenance.component';
import { DesignElementsComponent } from './design-elements/design-elements.component';
import { DesignElementsService } from './design-elements/design-elements.service';
import { EventRuleDetailsModule } from './event-rules/event-rule-details.module';
import { CaseviewEventsComponent } from './events/events.component';
import { FileInstructLinkComponent } from './file-instruct-link/file-instruct-link.component';
import { FileHistoryComponent } from './file-locations/file-history/file-history.component';
import { FileLocationsGridComponent } from './file-locations/file-locations-grid.component';
import { FileLocationsMaintenanceComponent } from './file-locations/file-locations-maintenance/file-locations-maintenance.component';
import { FileLocationsComponent } from './file-locations/file-locations.component';
import { OfficialNumbersComponent } from './official-numbers/official-numbers.component';
import { OfficialNumbersService } from './official-numbers/official-numbers.service';
import { IpxPolicingStatusComponent } from './policing/ipx-policing-status/ipx-policing-status.component';
import { RelatedCasesOtherDetailsComponent } from './related-cases/related-cases-other-details/related-cases-other-details.component';
import { RelatedCasesComponent } from './related-cases/related-cases.component';
import { RelatedCasesService } from './related-cases/related-cases.service';
import { RenewalsComponent } from './renewals/renewals.component';
import { StandingInstructionsComponent } from './standing-instructions/standing-instructions.component';

// tslint:disable-next-line: only-arrow-functions
export function caseViewRerouting(uiRouter: UIRouter): void {
    const transitionService = uiRouter.transitionService;
    transitionService.onBefore({}, (transition: Transition) => {
        const appContextService: AppContextService = transition.injector().get(AppContextService);
        const stateService = transition.router.stateService;

        appContextService.appContext$.subscribe((ctx: any) => {
            const params = transition.params();
            const programId = params.programId;
            if (programId && (ctx.programs.indexOf(programId) === -1)) {
                stateService.go(transition.to().name,
                    {
                        ...transition.params(),
                        programId: ''
                    },
                    {
                        inherit: true,
                        notify: false,
                        location: 'replace'
                    });
            }
        });
    });
}

const components = [
    CaseviewActionsComponent,
    CaseviewActionEventComponent,
    CaseviewEventsComponent,
    RenewalsComponent,
    StandingInstructionsComponent,
    RelatedCasesComponent,
    CriticalDatesComponent,
    OfficialNumbersComponent,
    FileInstructLinkComponent,
    RelatedCasesOtherDetailsComponent,
    DesignElementsComponent,
    FileLocationsComponent,
    FileLocationsGridComponent,
    FileLocationsMaintenanceComponent,
    CustomContentComponent,
    ChecklistsComponent,
    DesignElementsMaintenanceComponent,
    FileHistoryComponent,
    RegenerateChecklistComponent,
    AffectedCasesComponent,
    RecordalStepsComponent,
    RecordalStepElementComponent,
    RecordalStepElementControlsComponent,
    AffectedCasesFilterMenuComponent,
    AffectedCasesSetAgentComponent,
    RequestRecordalComponent
];
const providers = [
    CaseViewActionsService,
    CriticalDatesService,
    RelatedCasesService,
    OfficialNumbersService,
    DesignElementsService,
    KeepOnTopNotesViewService,
    AffectedCasesService,
    AffectedCasesSetAgentService,
    AttachmentPopupService
];

@NgModule({
    imports: [
        UIRouterModule.forChild({
            states: [
                caseViewState
            ],
            config: caseViewRerouting
        }),
        SharedModule,
        CasesCoreModule,
        EventNoteDetailsModule,
        CaseviewUpgradedComponentsModule,
        PortfolioModule,
        PipesModule,
        DirectivesModule,
        EventRuleDetailsModule,
        CaseViewNameViewModule
    ],
    exports: [FileLocationsGridComponent, AffectedCasesFilterMenuComponent],
    declarations: [
        CaseViewComponent,
        IpxPolicingStatusComponent,
        ...components,
        AddAffectedCaseComponent
    ],
    providers: [CaseDetailService, ...providers],
    entryComponents: [
        ...components
    ]
})
export class CaseViewModule { }
