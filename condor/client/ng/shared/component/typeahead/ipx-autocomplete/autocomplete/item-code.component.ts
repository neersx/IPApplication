import { ChangeDetectionStrategy, Component } from '@angular/core';
import { AutoCompleteContract } from './autocomplete.contract';

@Component({
    selector: 'item-code',
    templateUrl: './item-code.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class ItemCodeComponent implements AutoCompleteContract {
    item: any; keyField: string;
    codeField: string;
    textField: string;
    searchValue: string;
}
