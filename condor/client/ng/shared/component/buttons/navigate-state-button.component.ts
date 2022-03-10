import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
    selector: 'ipx-navigate-state-button',
    templateUrl: './navigate-state-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class NavigateStateButtonComponent {
     @Input() navigateUri: string;
    @Input() btnLabel: string;
    @Output() readonly onClick = new EventEmitter<any>();

    onButtonClick = (event: any): void => {
        this.onClick.emit(event);
    };
}