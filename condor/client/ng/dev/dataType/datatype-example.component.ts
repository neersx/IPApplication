import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
    selector: 'datatype',
    templateUrl: './dataType-example.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DataTypeExampleComponent {
    dataTypeValue: number;
}
