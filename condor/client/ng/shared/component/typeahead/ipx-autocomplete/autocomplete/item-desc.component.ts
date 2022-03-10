import { ChangeDetectionStrategy, Component } from '@angular/core';
import { AutoCompleteContract } from './autocomplete.contract';

@Component({
    selector: 'item-desc',
    templateUrl: './item-desc.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class ItemDescComponent implements AutoCompleteContract {
    item: any; keyField: string;
    codeField: string;
    textField: string;
    searchValue: string;
}
