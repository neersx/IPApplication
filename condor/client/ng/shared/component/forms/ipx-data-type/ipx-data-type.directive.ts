import { Directive, ElementRef, forwardRef, Input, OnInit } from '@angular/core';
import { AbstractControl, NG_VALIDATORS, Validator } from '@angular/forms';
import { dataTypeEnum } from './datatype-enum';

@Directive({
    selector: '[ipx-data-type]',
    providers: [
        { provide: NG_VALIDATORS, useExisting: forwardRef(() => DataTypeDirective), multi: true }
    ]
})
export class DataTypeDirective implements OnInit, Validator {
    @Input('ipx-data-type') ipxDataType: string;
    @Input() textField: string;
    dataType: string;
    tagName: string;
    constructor(public el: ElementRef) {
        this.tagName = el.nativeElement.localName.toLowerCase();
    }

    ngOnInit(): void {
        this.dataType = this.ipxDataType.toLowerCase();
    }

    validate(c: AbstractControl): { [key: string]: any } {
        let errormsg = {};
        if (this.dataType && c.value) {
            if (!this.isValid(c.value)) {
                c.markAsTouched();
                errormsg = this.errorMessage(this.dataType);
            } else {
                this.parse(c.value);
            }
        }

        return errormsg;
    }

    getViewValue(value: any): any {
        if (!value) {
            return null;
        }
        if (this.tagName === 'ipx-text-dropdown-group') {
            return value[this.textField || 'text'];
        }

        if (this.dataType === dataTypeEnum.positivedecimal) {
            return this.validateAndAddZeroes(value);
        }

        return value;
    }
    normalise(val: any): any {
        if (val == null) {
            return null;
        } else if (isNaN(val)) {
            return null;
        }

        return val;
    }
    isValid(viewValue: any): any {
        const INTEGER_REGEXP = /^\-?\d+$/;
        const DECIMAL_REGEXP = /^\-?\d+(\.\d+)?$/;
        const POSITIVEINTEGER_REGEXP = /^[1-9][0-9]*$/;
        const NON_NEGATIVE_INTEGER_REGEXP = /^[0-9]*$/;
        const POSITIVEDECIMAL_REGEXP = /^\d+(\.\d+)?$/;
        const value = this.getViewValue(viewValue);

        if (!value) {
            return true;
        }

        switch (this.dataType) {
            case dataTypeEnum.integer: {
                return INTEGER_REGEXP.test(value);
            }
            case dataTypeEnum.decimal: {
                return DECIMAL_REGEXP.test(value);
            }
            case dataTypeEnum.positiveinteger: {
                return POSITIVEINTEGER_REGEXP.test(value);
            }
            case dataTypeEnum.nonnegativeinteger: {
                return NON_NEGATIVE_INTEGER_REGEXP.test(value);
            }
            case dataTypeEnum.positivedecimal: {
                return POSITIVEDECIMAL_REGEXP.test(value);
            }
            default: {
                return value;
            }
        }
    }

    validateAndAddZeroes(num: any): any {
        if (num && !Number.isNaN(+num)) {
            let dec = num.toString().split('.')[1];
            if (!dec) {
                dec = '00';
            }

            return Number(num).toFixed(2);
        }

        return num;
    }

    parse(viewValue: any): any {
        let result: any;
        switch (this.dataType) {
            case dataTypeEnum.positiveinteger:
            case dataTypeEnum.integer:
            case dataTypeEnum.nonnegativeinteger: {
                result = this.normalise(parseInt(this.getViewValue(viewValue), 10));
                break;
            }
            case dataTypeEnum.decimal: {
                result = this.normalise(parseFloat(this.getViewValue(viewValue)));
                break;
            }
            case dataTypeEnum.positivedecimal: {
                result = this.normalise(parseFloat(this.getViewValue(viewValue)));
                break;
            }
            default: {
                result = viewValue;
                break;
            }
        }
        if (this.tagName === 'ipx-text-dropdown-group') {
            viewValue[this.textField || 'text'] = result;
        } else {
            // tslint:disable-next-line: no-parameter-reassignment
            viewValue = result;
        }

        return viewValue;

    }

    errorMessage(error: string): any {
        switch (error) {
            case dataTypeEnum.integer: {
                return { integer: true };
            }
            case dataTypeEnum.decimal: {
                return { decimal: true };
            }
            case dataTypeEnum.positiveinteger: {
                return { positiveinteger: true };
            }
            case dataTypeEnum.nonnegativeinteger: {
                return { nonnegativeinteger: true };
            }
            case dataTypeEnum.positivedecimal: {
                return { decimal: true };
            }
            default: {
                return null;
            }
        }
    }

}