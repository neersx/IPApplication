import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, EventEmitter, Input, OnDestroy, Optional, Output, Self } from '@angular/core';
import { ControlValueAccessor, NgControl } from '@angular/forms';
import { ReplaySubject, Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import * as _ from 'underscore';
@Component({
    template: '',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class ElementBaseComponent<T = any> implements ControlValueAccessor, OnDestroy {
    @Input() warningText: string;
    @Input() disabled: boolean;
    @Output() readonly onBlur: EventEmitter<any> = new EventEmitter<any>();
    @Output() readonly onChange: EventEmitter<any> = new EventEmitter<any>();
    @Output() readonly onFocus: EventEmitter<any> = new EventEmitter<any>();

    destroy: ReplaySubject<any> = new ReplaySubject<any>(1);
    private _val: T;
    get value(): T {
        return this._val;
    }
    set value(value: T) {
        this._val = value;
        this.cdr.markForCheck();
    }
    isControlEdited: boolean;
    constructor(@Self() @Optional() public control: NgControl, public el: ElementRef, public cdr: ChangeDetectorRef) {
        this.control && (this.control.valueAccessor = this);
        this.isControlEdited = this.el.nativeElement.getAttribute('apply-edited') != null ? true : false;
        if (this.control && this.control.statusChanges) {
            this.control.statusChanges.pipe(takeUntil(this.destroy)).subscribe(v => {
                this.cdr.markForCheck();
            });
        }
    }
    ngOnDestroy(): void {
        this.destroy.next(null);
        this.destroy.complete();
    }

    warning = (): string => {
        return _.isFunction(this.warningText) ? this.warningText() : null;
    };

    get invalid(): boolean {
        return this.control ? this.control.invalid : false;
    }

    showError = (): boolean => {
        if (!this.control) {
            return false;
        }
        const { dirty } = this.control;

        return this.invalid ? dirty && this.isStable() : false;
    };

    isStable = (): boolean => {
        return true;
    };

    getError = () => {
        if (!this.control) {
            return [];
        }

        const { errors } = this.control;

        if (!errors) { return null; }
        const err = Object.keys(errors).map(key => 'field.errors.' + key);

        return this.showError() && err.length > 0 ? err[0] : '';
    };

    getErrorParams = () => {
        if (!this.control) {
            return [];
        }

        const { errors } = this.control;
        if (errors) {
            if (errors.maxlength) {
                errors.length = errors.maxlength.requiredLength;
            }
            if (errors.minlength) {
                errors.length = errors.minlength.requiredLength;
            }
            if (errors.max) {
                errors.max = errors.max.max ? errors.max.max : errors.max;
            }
            if (errors.min) {
                errors.min = errors.min.min ? errors.min.min : errors.min;
            }
        }

        return _.extend(errors, this.getCustomErrorParams());
    };

    getCustomErrorParams = (): any => ({});
    // tslint:disable-next-line:no-empty
    _onChange: any = () => { };
    // tslint:disable-next-line:no-empty
    _onTouch: any = () => { };

    writeValue = (value: T) => {
        this.value = value;
    };

    registerOnChange = (fn: any) => {
        this._onChange = fn;
    };

    setDisabledState(isDisabled: boolean): void {
        this.disabled = isDisabled;
    }

    registerOnTouched = (fn: any) => {
        this._onTouch = fn;
    };

    onKeyup = (event: any) => {
        this._onChange(event.target ? event.target.value : null);
    };

    change = (event: any) => {
        this._onChange(event.target ? event.target.value : null);
        this.onChange.emit(event);
    };

    onModelChange = (newValue: any) => {
        this._onChange(newValue);
        this.onChange.emit(newValue);
    };

    controledited(): boolean {
        if (this.control != null) {
            return (this.control.dirty && this.isControlEdited) ? true : false;
        }
    }

    blur = () => {
        this.onBlur.emit();
    };

    touch = () => {
        this._onTouch();
    };

    getId(id?: string): string {
        return id ? id + '_' + Math.random().toString(36).substring(2)
            : Math.random().toString(36).substring(2);
    }

    focus = () => {
        this.onFocus.emit();
    };
}