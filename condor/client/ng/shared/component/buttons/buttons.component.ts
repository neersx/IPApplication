import { ChangeDetectionStrategy, Component, Directive, EventEmitter, Input, Output } from '@angular/core';

@Component({
    selector: 'ipx-button',
    template: '',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class ButtonComponent {
    @Input() disabled: boolean;
    @Input() displayLabel = false;
    @Output() readonly onclick = new EventEmitter<any>();

    onClickButton = (event: Event): void => {
        this.onclick.emit(event);
    };
}

@Component({
    selector: 'ipx-add-button',
    templateUrl: './add-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class AddButtonComponent extends ButtonComponent { }

@Component({
    selector: 'ipx-save-button',
    templateUrl: './save-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class SaveButtonComponent extends ButtonComponent {
}

@Component({
    selector: 'ipx-history-button',
    templateUrl: './history-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class HistoryButtonComponent extends ButtonComponent { }

@Component({
    selector: 'ipx-apply-button',
    templateUrl: './apply-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class ApplyButtonComponent extends ButtonComponent { }

@Component({
    selector: 'ipx-preview-button',
    templateUrl: './preview-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class PreviewButtonComponent {
    previewActive: boolean;
    @Input() get isPreviewActive(): boolean {
        return this.previewActive;
    }
    @Output() readonly isPreviewActiveChange = new EventEmitter();

    set isPreviewActive(val) {
        this.previewActive = val;
        this.isPreviewActiveChange.emit(this.previewActive);
    }
}

@Component({
    selector: 'ipx-revert-button',
    templateUrl: './revert-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class RevertButtonComponent extends ButtonComponent {
    @Input() tooltipTitle = 'button.revert';
}

@Component({
    selector: 'ipx-close-button',
    templateUrl: './close-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CloseButtonComponent extends ButtonComponent { }

@Component({
    selector: 'ipx-clear-button',
    templateUrl: './clear-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class ClearButtonComponent extends ButtonComponent { }

@Component({
    selector: 'ipx-step-button',
    templateUrl: './step-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class StepButtonComponent extends ButtonComponent {
    @Input() stepNo: Number;
    @Input() defaultStep: boolean;
    @Input() title: string;
}

@Component({
    selector: 'ipx-icon-button',
    templateUrl: './icon-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IconButtonComponent extends ButtonComponent {
    @Input() buttonIcon: string;
    @Input() buttonText: string;
    @Input() tooltipText: string;
}

@Component({
    selector: 'ipx-advanced-search-button',
    templateUrl: './advanced-search-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class AdvancedSearchButtonComponent extends ButtonComponent { }

@Component({
    selector: 'ipx-delete-button',
    templateUrl: './delete-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DeleteButtonComponent extends ButtonComponent { }

@Component({
    selector: 'ipx-edit-button',
    templateUrl: './edit-button.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class EditButtonComponent extends ButtonComponent { }
