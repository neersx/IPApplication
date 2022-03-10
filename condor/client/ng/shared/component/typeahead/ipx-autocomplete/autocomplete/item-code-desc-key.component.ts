import { ChangeDetectionStrategy, Component } from '@angular/core';
import { AutoCompleteContract } from './autocomplete.contract';

@Component({
    selector: 'item-code-desc-key',
    templateUrl: './item-code-desc-key.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class ItemCodeDescKeyComponent implements AutoCompleteContract {
    item: any;
    keyField: string;
    codeField: string;
    textField: string;
    searchValue: string;
}
