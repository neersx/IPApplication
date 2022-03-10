import { NgModule } from '@angular/core';
import { BaseCommonModule } from 'shared/base.common.module';
import { DirectivesModule } from 'shared/directives/directives.module';
import { TooltipModule } from '../tooltip/tooltip.module';
import { IpxDynamicTopicClassDirective } from './ipx-dynamic-topic-class-directive';
import { IpxTopicHostDirective } from './ipx-topic-host.directive';
import { IpxTopicMenuItemComponent } from './ipx-topic-menu-item.component';
import { IpxTopicResolverComponent } from './ipx-topic-resolver';
import { IpxTopicsHeaderComponent } from './ipx-topics-header.component';
import { IpxTopicsComponent } from './ipx-topics.component';
import { TooltipTemplatesComponent } from './templates/tooltip-templates.component';
import { TopicGroupDetailsComponent } from './topic-group-details.componenet';

@NgModule({
    imports: [
        BaseCommonModule,
        TooltipModule,
        DirectivesModule
    ],
    declarations: [
        IpxTopicsComponent,
        IpxTopicMenuItemComponent,
        IpxTopicResolverComponent,
        IpxTopicsHeaderComponent,
        TooltipTemplatesComponent,
        IpxTopicHostDirective,
        IpxDynamicTopicClassDirective,
        TopicGroupDetailsComponent
    ],
    exports: [
        IpxTopicsComponent,
        IpxTopicMenuItemComponent,
        IpxTopicResolverComponent,
        IpxTopicsHeaderComponent,
        TooltipTemplatesComponent,
        IpxTopicHostDirective,
        IpxDynamicTopicClassDirective,
        TopicGroupDetailsComponent
    ]

})
export class TopicsModule { }