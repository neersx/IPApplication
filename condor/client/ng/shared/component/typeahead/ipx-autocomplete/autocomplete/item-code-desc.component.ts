import { ChangeDetectionStrategy, Component } from '@angular/core';
import { AutoCompleteContract } from './autocomplete.contract';

@Component({
    selector: 'item-code-desc',
    templateUrl: './item-code-desc.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class ItemCodeDescComponent implements AutoCompleteContract {
    item: any;
    keyField: string;
    codeField: string;
    textField: string;
    searchValue: string;
}
