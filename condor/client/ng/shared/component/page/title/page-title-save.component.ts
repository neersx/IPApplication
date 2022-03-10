import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import * as _ from 'underscore';

@Component({
    selector: 'ipx-page-title-save',
    templateUrl: './page-title-save.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class PageTitleSaveComponent implements OnInit {
    @Input() title: string;
    @Input() subtitle: string;
    @Output() readonly onDiscard = new EventEmitter<any>();
    @Output() readonly onSave = new EventEmitter<any>();
    @Output() readonly onDelete = new EventEmitter<any>();
    @Input() isSaveEnabled: Function;
    @Input() isDiscardEnabled: Function;
    @Input() isDeleteEnabled: Function;
    @Input() isDiscardAvailable: Function;
    @Input() isSaveAvailable: Function;
    isDeleteAvailable: boolean;
    isDiscardAvailableInternal: boolean;
    isSaveAvailableInternal: boolean;

    constructor(private readonly notificationService: NotificationService) {
    }

    ngOnInit(): void {
        this.isDeleteAvailable = this.onDelete.observers.length > 0 || this.isDeleteEnabled !== undefined;
        this.isDiscardAvailableInternal = this.onDiscard.observers.length > 0 || this.isDiscardAvailable !== undefined;
        this.isSaveAvailableInternal = this.onSave.observers.length > 0 || this.isSaveAvailable !== undefined;
    }

    doDiscard = (): any =>
        this.notificationService.discard().then(() => {
            this.onDiscard.emit();
        });

    doSave = (): any => { this.onSave.emit(); };

    doDelete = (): any => { this.onDelete.emit(); };
}
