import { EventEmitter } from '@angular/core';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { SanityCheckRuleCaseCharacteristicsComponent } from './case-characteristics/case-characteristics.component';
import { SanityCheckRuleCaseNameComponent } from './case-name/case-name.component';
import { SanityCheckRuleEventComponent } from './event/event.component';
import { SanityCheckRuleNameCharacteristicsComponent } from './name-characteristics/name-characteristics.component';
import { SanityCheckRuleOtherComponent } from './other/other.component';
import { SanityCheckRuleOverviewComponent } from './rule-overview/rule-overview.component';
import { SanityCheckRuleStandingInstructionComponent } from './standing-instruction/standing-instruction.component';

export class SanityCheckRuleOverviewTopic extends Topic {
    readonly key = 'ruleOverview';
    readonly title = 'sanityCheck.configurations.maintenance.ruleOverview.title';
    readonly component = SanityCheckRuleOverviewComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: any) {
        super();
    }
}

export class SanityCheckCaseCharacteristicsTopic extends Topic {
    readonly key = 'caseCharacteristics';
    readonly title = 'sanityCheck.configurations.maintenance.caseCharacteristics.title';
    readonly component = SanityCheckRuleCaseCharacteristicsComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: any = null) {
        super();
    }
}

export class SanityCheckCaseNameTopic extends Topic {
    readonly key = 'caseName';
    readonly title = 'sanityCheck.configurations.maintenance.caseName.title';
    readonly component = SanityCheckRuleCaseNameComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: any = null) {
        super();
    }
}

export class SanityCheckStandingInstructionTopic extends Topic {
    readonly key = 'standingInstruction';
    readonly title = 'sanityCheck.configurations.maintenance.standingInstruction.title';
    readonly component = SanityCheckRuleStandingInstructionComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: any = null) {
        super();
    }
}

export class SanityCheckEventTopic extends Topic {
    readonly key = 'event';
    readonly title = 'sanityCheck.configurations.maintenance.event.title';
    readonly component = SanityCheckRuleEventComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: any = null) {
        super();
    }
}

export class SanityCheckOtherTopic extends Topic {
    readonly key = 'other';
    readonly title = 'sanityCheck.configurations.maintenance.other.title';
    readonly component = SanityCheckRuleOtherComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: any = null) {
        super();
    }
}

export class SanityCheckNameCharacteristicsTopic extends Topic {
    readonly key = 'nameCharacteristics';
    readonly title = 'sanityCheck.configurations.maintenance.nameCharacteristics.title';
    readonly component = SanityCheckRuleNameCharacteristicsComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: any = null) {
        super();
    }
}