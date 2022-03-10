import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { Topic } from './ipx-topic.model';

@Component({
    selector: 'ipx-topic-menu-item',
    templateUrl: './ipx-topic-menu-item.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxTopicMenuItemComponent implements OnInit {

    @Input() topic: Topic;

    constructor(private readonly cdr: ChangeDetectorRef) {
    }

    ngOnInit(): void {
        if (this.topic.setCount) {
            this.topic.setCount.subscribe((s: number) => this.setCount(s));
        }
    }

    setCount(count: number): void {
        this.topic.count = count;
        this.cdr.markForCheck();
    }
}