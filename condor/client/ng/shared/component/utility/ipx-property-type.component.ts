import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { PropertyIconService } from 'shared/shared-services/property-icon.service';

@Component({
    selector: 'ipx-property-type-icon',
    template: '<span><img *ngIf="image" [src]="\'data:image/PNG;base64,\'+image"></span>',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxPropertyTypeIconComponent implements OnInit {
    @Input() imageKey: number;
    image: any;
    constructor(private readonly service: PropertyIconService) { }

    ngOnInit(): void {
        this.service.getPropertyTypeIcon$(this.imageKey).subscribe(data => {
            this.image = data.image;
        });
    }
}
