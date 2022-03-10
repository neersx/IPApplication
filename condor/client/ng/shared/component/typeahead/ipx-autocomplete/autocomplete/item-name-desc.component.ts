import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
    selector: 'item-name-desc',
    templateUrl: './item-name-desc.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class ItemNameDescComponent {
    item: any;
    searchValue: string;
}
