import { EventEmitter } from '@angular/core';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { TaxCodeOverviewComponent } from './tax-code-overview.component';
import { TaxCodeRatesComponent } from './tax-code-rates.component';

export class TaxCodeOverviewTopic extends Topic {
    readonly key = 'Overview';
    readonly title = 'taxCode.overview.title';
    readonly component = TaxCodeOverviewComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: any) {
        super();
    }
}

export class TaxCodeRatesTopic extends Topic {
    readonly key = 'Rates';
    readonly title = 'taxCode.rates.taxRateHeader';
    readonly component = TaxCodeRatesComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: any) {
        super();
    }
}