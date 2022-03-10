import { ChangeDetectionStrategy, Component, Directive, ElementRef, Injector, Input } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';
import { IppAvailability } from 'cases/case-view/case-detail.service';
import { caseViewTopicTitles } from 'cases/case-view/case-view-topic-titles';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';

@Directive({
    selector: 'ip-caseview-designated-countries-upg'
})
export class CaseDesignatedCountriesDirective extends UpgradeComponent implements TopicContract {
    @Input() topic: CaseDesignatedCountriesTopic;
    constructor(elementRef: ElementRef, injector: Injector) {
        super('ipCaseviewDesignatedCountriesWrapper', elementRef, injector);
    }
}

@Component({
    selector: 'ip-caseview-designated-countries-component-upg',
    template: '<ip-caseview-designated-countries-upg [(topic)]="topic"></ip-caseview-designated-countries-upg>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseDesignatedCountriesComponent implements TopicContract {
    @Input() topic: CaseDesignatedCountriesTopic;
}

export class CaseDesignatedCountriesTopic extends Topic {
    readonly key = 'designatedCountries';
    readonly title = caseViewTopicTitles.designatedJurisdiction;
    readonly component = CaseDesignatedCountriesComponent;
    constructor(public params: CaseDesignatedCountriesTopicParams) {
        super();
    }
}

export class CaseDesignatedCountriesTopicParams extends TopicParam {
    showWebLink: boolean;
    ippAvailability: IppAvailability;
}
