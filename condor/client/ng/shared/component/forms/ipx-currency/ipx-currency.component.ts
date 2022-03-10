import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
    selector: 'ipx-currency',
    templateUrl: 'ipx-currency.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxCurrencyComponent {
    @Input() value: number;
    @Input() decimalPlaces: number;
    @Input() currencyCode?: string;
    @Input() renderHyperlink: Boolean;
    @Output() readonly onClick = new EventEmitter();

    onClickHyperLink = (event: Event): void => {
        this.onClick.emit(event);
    };
}