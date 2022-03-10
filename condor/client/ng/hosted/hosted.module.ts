import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { AdjustWipComponent } from 'accounting/wip/adjust-wip/adjust-wip.component';
import { AdjustWipService } from 'accounting/wip/adjust-wip/adjust-wip.service';
import { SplitWipHeaderComponent } from 'accounting/wip/split-wip/split-wip-header.component';
import { SplitWipComponent } from 'accounting/wip/split-wip/split-wip.component';
import { LocalCurrencyFormatPipe } from 'shared/pipes/local-currency-format.pipe';
import { SharedModule } from 'shared/shared.module';
import { ComponentLoaderConfigService } from './component-loader-config';
import { HostedCaseTopicComponent } from './hosted-topic/hosted-case-topic.component';
import { HostedNameTopicComponent } from './hosted-topic/hosted-name-topic.component';
import { HostedComponent } from './hosted.component';
import { hostedActivityAttachmentMaintenanceState, hostedAdditionalCaseInfoState, hostedAdjustWipState, hostedCaseAttachmentMaintenanceState, hostedCasePresentationState, hostedCaseSearchResultState, hostedCaseViewState, hostedGenerateDocumentState, hostedNameAttachmentMaintenanceState, hostedNameViewState, hostedSplitWipState, hostedStartTimerForCaseState, hostedTimerWidgetState } from './hosted.states';
import { IpxComponentResolverComponent } from './ipx-component-resolver';

@NgModule({
   imports: [
      SharedModule,
      UIRouterModule.forChild({
         states: [
            hostedCaseViewState,
            hostedCaseSearchResultState,
            hostedCasePresentationState,
            hostedNameViewState,
            hostedAdditionalCaseInfoState,
            hostedCaseAttachmentMaintenanceState,
            hostedNameAttachmentMaintenanceState,
            hostedActivityAttachmentMaintenanceState,
            hostedStartTimerForCaseState,
            hostedGenerateDocumentState,
            hostedTimerWidgetState,
            hostedAdjustWipState,
            hostedSplitWipState
         ]
      })
   ],
   declarations: [HostedComponent, IpxComponentResolverComponent, HostedCaseTopicComponent, HostedNameTopicComponent, AdjustWipComponent, SplitWipComponent, SplitWipHeaderComponent],
   providers: [ComponentLoaderConfigService, AdjustWipService],
   entryComponents: [HostedComponent, HostedCaseTopicComponent, HostedNameTopicComponent, AdjustWipComponent],
   exports: [LocalCurrencyFormatPipe, SplitWipHeaderComponent]
})
export class HostedModule { }
