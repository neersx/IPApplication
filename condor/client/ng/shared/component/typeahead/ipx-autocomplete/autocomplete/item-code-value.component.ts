import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
    selector: 'item-code-value',
    templateUrl: './item-code-value.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class ItemCodeValueComponent {
    item: any;
    searchValue: string;
}
