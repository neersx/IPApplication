import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { EventCategoryIconService } from 'shared/shared-services/event-category-icon.service';

@Component({
    selector: 'ipx-event-category-icon',
    template: '<span><img *ngIf="image" [src]="\'data:image/PNG;base64,\'+image" title="{{imageTitle}}"></span>',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxEventCategoryIconComponent implements OnInit {
    @Input() imageKey: number;
    @Input() maxWidth?: number;
    @Input() maxHeight?: number;
    @Input() tooltipText?: string;
    image: any;
    imageTitle: string;

    constructor(private readonly service: EventCategoryIconService,
                    private readonly cdRef: ChangeDetectorRef) { }

    ngOnInit(): void {
        this.service.getEventCategoryIcon$(this.imageKey, this.maxWidth, this.maxHeight).subscribe(data => {
            this.image = data.image;
            this.imageTitle = this.tooltipText;
            this.cdRef.markForCheck();
        });
    }
}
