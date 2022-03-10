import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { ElementBaseComponent } from '../element-base.component';

@Component({
    selector: 'ipx-multistate-checkbox',
    templateUrl: './ipx-multistate-checkbox.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxMultiStateCheckboxComponent extends ElementBaseComponent<boolean> implements OnInit {
    checkboxModel = { status: null };

    ngOnInit(): void {
        // tslint:disable-next-line: strict-boolean-expressions
        const attr = this.el.nativeElement.attributes;
        if (attr.disabled) {
            this.disabled = true;
        }
    }

    modelChange(modelStatus: any): void {
        switch (modelStatus.status) {
            case 1: {
                modelStatus.status = 2;
                break;
            }
            case 0:
            case null: {
                modelStatus.status = 1;
                break;
            }
            case 2: {
                modelStatus.status = 0;
                break;
            }
            default: {
                modelStatus.status = 0;
                break;
            }
        }
        this._onChange(modelStatus.status);
        this.onChange.emit(modelStatus.status);
    }

    writeValue = (value: any) => {
        this.checkboxModel.status = value;
    };
}
