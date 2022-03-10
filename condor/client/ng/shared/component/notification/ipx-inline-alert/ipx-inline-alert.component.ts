import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';

@Component({
    selector: 'ipx-inline-alert',
    templateUrl: './ipx-inline-alert.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxInlineAlertComponent implements OnInit {
    @Input() text: string;
    @Input() type: string;
    @Input() textParams: string;
    @Input() isError: boolean;

    alertClass: string;
    ngOnInit(): void {
        this.alertClass = !this.type ? 'alert-info' : 'alert-' + this.type;
    }
}
