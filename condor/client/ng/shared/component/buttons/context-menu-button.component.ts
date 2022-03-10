import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output, ViewChild } from '@angular/core';
import { ContextMenuComponent, MenuEvent } from '@progress/kendo-angular-menu';

@Component({
    selector: 'ipx-context-menu-button',
    templateUrl: './context-menu-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class ContextMenuButtonComponent {
    @Input() menuItems: any;
    @Output() readonly onClick = new EventEmitter();
    @ViewChild('contextMenu', { static: true }) contextMenu: ContextMenuComponent;

    onButtonClick = (event: any): void => {
        this.onClick.emit(event);
        if (this.contextMenu) {
            this.contextMenu.show({ left: event.view.window.innerWidth - event.pageX > 200 ? event.pageX : event.pageX - 200, top: event.pageY });
        }
    };

    onMenuItemSelected = (event: MenuEvent) => {
        event.item.action();
    };
}