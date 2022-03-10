import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import * as _ from 'underscore';

@Component({
    selector: 'ipx-boolean-column',
    templateUrl: './ipx-boolean-column.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxBooleanColumnComponent implements OnInit {
    @Input() presentationType: any;
    @Input() dataItem: any;
    item: any;
    ngOnInit(): void {
        (typeof this.dataItem === 'boolean')
            ? this.item = this.dataItem
            : this.item = this.dataItem
                ? this.dataItem.value : null;
    }
}
