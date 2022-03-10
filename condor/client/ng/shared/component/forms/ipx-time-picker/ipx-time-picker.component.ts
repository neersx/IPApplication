import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, OnChanges, OnInit, Optional, Self, SimpleChanges, ViewChild } from '@angular/core';
import { NgControl } from '@angular/forms';
import { TimePickerComponent } from '@progress/kendo-angular-dateinputs';
import { LocaleService } from 'core/locale.service';
import { ElementBaseComponent } from '../element-base.component';

@Component({
    selector: 'ipx-time-picker',
    templateUrl: 'ipx-time-picker.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [
        LocaleService,
        TimePickerComponent
    ]
})
export class IpxTimePickerComponent extends ElementBaseComponent<Date> implements OnChanges, OnInit {
    bsConfig: any;
    @Input() label: string;
    @Input() disabled: boolean;
    @Input() showSeconds: boolean;
    @Input() format = 'HH:mm:ss';
    @Input() placeHolder = null;
    @Input() min = null;
    @Input() max = null;
    @Input() showNowButton = true;
    @Input() canBeEmpty = true;
    @Input() is12HoursFormat = false;
    @Input() isElapsedTime = false;
    @Input() timeInterval?: number;
    @ViewChild(TimePickerComponent, { static: true }) wrapper: TimePickerComponent;

    constructor(@Self() @Optional() public control: NgControl, public el: ElementRef, cdr: ChangeDetectorRef) {
        super(control, el, cdr);
    }

    ngOnInit(): void {
        this.wrapper.steps = this.timeInterval ? { minute: this.timeInterval } : null;
    }

    showError = (): boolean => {
        if (!this.control) {
            return false;
        }

        const { dirty } = this.control;

        return this.invalid ? dirty : false;
    };

    getError = () => {
        if (!this.control) {
            return [];
        }

        const { errors } = this.control;

        if (!errors) { return null; }

        return errors.errorMessage;
    };

    timeChanged = (e: Date): void => {
        this.value = this.isElapsedTime ? new Date(1899, 0, 1, e.getHours(), e.getMinutes(), e.getSeconds()) : (!!this.showSeconds ? e : new Date(e.setSeconds(0)));
        this._onChange(this.value);
        this.onChange.emit(this.value);
    };

    ngOnChanges(changes: SimpleChanges): void {
        if (!!changes.format) {
            this.format = changes.format.currentValue;
        }
        if (!!changes.is12HoursFormat) {
            this.is12HoursFormat = changes.is12HoursFormat.currentValue;
        }
        if (!!changes.showSeconds) {
            this.showSeconds = changes.showSeconds.currentValue;
        }
        this.cdr.detectChanges();
    }

    _onBlur(): void {
        if (!this.value) {
            this._onChange(this.wrapper.input.inputElement.value);
        }
        this._onTouch();
    }

    onclick(timepicker): void {
        const input = timepicker.element.nativeElement.querySelector('input');
        input.select();
    }
}
