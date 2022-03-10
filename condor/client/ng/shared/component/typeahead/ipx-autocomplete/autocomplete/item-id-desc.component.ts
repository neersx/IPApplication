import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
    selector: 'item-id-desc',
    templateUrl: './item-id-desc.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class ItemIdDescComponent {
    item: any;
    searchValue: string;
}
