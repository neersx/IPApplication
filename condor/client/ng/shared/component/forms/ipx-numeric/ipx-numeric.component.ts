import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, OnInit, Optional, Self } from '@angular/core';
import { NgControl } from '@angular/forms';
import { NumberFormatOptions } from '@progress/kendo-angular-intl';
import { AppContextService } from 'core/app-context.service';
import { BehaviorSubject } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { ElementBaseComponent } from './../element-base.component';

@Component({
    selector: 'ipx-numeric',
    templateUrl: 'ipx-numeric.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxNumericComponent extends ElementBaseComponent implements OnInit {
    @Input() isCurrency?: boolean;
    @Input() currency?: string;
    @Input() label?: string;
    @Input() minValue?: number;
    @Input() maxValue?: number;
    @Input() maxLength?: number;
    @Input() customStyle: string;
    @Input() isDecimal = false;
    @Input() roundUpto?: number;
    @Input() width: string;
    @Input() autoCorrect: boolean | false;
    @Input() errorStyle = { marginLeft: '-229px' };
    showError$ = new BehaviorSubject(false);

    formatOptions?: NumberFormatOptions;
    left: boolean;
    bold: boolean;
    constructor(private readonly appCtx: AppContextService, el: ElementRef, @Self() @Optional() public control: NgControl, cdr: ChangeDetectorRef) {
        super(control, el, cdr);

        this.left = this.el.nativeElement.hasAttribute('left');
        this.bold = this.el.nativeElement.hasAttribute('bold');
    }

    ngOnInit(): void {
        if (this.isCurrency) {
            this.appCtx.appContext$
                .pipe(take(1))
                .subscribe((appCtxValue: any) => {
                    const localCurrencyCode = this.currency || appCtxValue.user.preferences.currencyFormat.localCurrencyCode;
                    const localDecimalPlaces = appCtxValue.user.preferences.currencyFormat.localDecimalPlaces;
                    this.formatOptions = {
                        style: 'accounting',
                        currency: localCurrencyCode,
                        currencyDisplay: 'code',
                        minimumFractionDigits: localDecimalPlaces,
                        maximumFractionDigits: localDecimalPlaces
                    };
                });
        } else {
            this.formatOptions = {
                minimumFractionDigits: 0,
                maximumFractionDigits: 0
            };
        }

        if (this.control && this.control.control) {
            if (this.control.control.dirty) {
                this.updatecontrolState();
            }
            this.control.control.statusChanges.subscribe((value) => {
                if (value) {
                    this.updatecontrolState();
                }
            });
        }

        if (this.isDecimal) {
            this.appCtx.appContext$
                .pipe(take(1))
                .subscribe((appCtxValue: any) => {
                    const localDecimalPlaces = appCtxValue.user.preferences.currencyFormat.localDecimalPlaces;
                    this.formatOptions = {
                        currencyDisplay: 'symbol',
                        minimumFractionDigits: localDecimalPlaces,
                        maximumFractionDigits: localDecimalPlaces
                    };
                });
        }
        this.cdr.markForCheck();
    }

    change = (value: number) => {
        const round = this.round(value);
        this._onChange(round);
        this.onChange.emit(round);
        this.control.control.markAsDirty();
        this.control.control.markAsTouched();
        this.cdr.detectChanges();
    };

    updatecontrolState = () => {
        this.control.control.markAsDirty();
        this.control.control.markAsTouched();
        this.showError$.next(this.showError());
    };

    clearValue = () => {
        this.el.nativeElement.querySelector('input').value = null;
        this.el.nativeElement.querySelector('input').ariaValueNow = null;
        this.control.control.markAsPristine();
    };

    onKeyup = (event: any) => {
        if (this.maxLength && event.target.value.length > this.maxLength) {
            event.target.value = event.target.value.slice(0, this.maxLength);
        }
    };

    round = (value: number): number => {
        if (!this.roundUpto || !value) {

            return value;
        }

        return Number(value.toFixed(this.roundUpto));
    };
}
