import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnDestroy, OnInit, Output } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { ElementBaseComponent } from '../element-base.component';

@Component({
    selector: 'ipx-text-field',
    templateUrl: './ipx-text-field.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxTextFieldComponent extends ElementBaseComponent<string> implements OnInit, OnDestroy {
    @Input() label: string;
    @Input() rows: number | undefined;
    @Input() mask: boolean;
    @Input() placeholder: string;
    @Input() errorParam: any;
    @Input() numberOnly?: boolean;
    @Input() loading?: boolean;
    @Input() autoCompleteName;
    @Input() fieldClass: string;
    @Input() decimalPlaces?: number;
    @Output() readonly onClick = new EventEmitter();
    private focusSubscription;

    getCustomErrorParams = () => ({
        errorParam: this.errorParam
    });
    multiLine = false;
    applySqlHighlighter = false;
    identifier: string;
    singleLineFieldType: string;
    config: any;
    showError$ = new BehaviorSubject(false);

    writeValue = (value: any) => {
        this.value = this.decimalPlaces ? this.validateAndAddZeroes(value) : value;
    };

    change = (event: any) => {
        this._onChange(event.target ? event.target.value : null);
        if (this.control.control && !this.control.control.errors && this.decimalPlaces && event.target) {
            event.target.value = this.validateAndAddZeroes(event.target.value);
        }
        this.onChange.emit(event);
    };

    validateAndAddZeroes(num: any): any {
        if (this.decimalPlaces && num && !Number.isNaN(+num)) {
            let dec = num.toString().split('.')[1];
            if (!dec) {
                dec = '00';
            }
            const len = dec && dec.length === this.decimalPlaces ? dec.length : this.decimalPlaces;

            return Number(num).toFixed(len);
        }

        return num;
    }

    ngOnInit(): any {
        this.singleLineFieldType = this.mask ? 'password' : this.numberOnly ? 'number' : 'text';
        this.identifier = this.getId('textfield');
        this.multiLine = this.el.nativeElement.hasAttribute('multiline');
        this.applySqlHighlighter = this.el.nativeElement.hasAttribute('sqlHighlighter');
        if (this.applySqlHighlighter) {
            this.setCodeMirrorConfig();
        }
        if (this.multiLine && this.rows === undefined) {
            this.rows = 2;
        }

        this.focusSubscription = this.onFocus.subscribe(() => {
            const elem = this.el.nativeElement.querySelector('input, textarea');
            if (!!elem) {
                elem.focus();
            }
        });
        if (this.control.control) {
            this.control.control.statusChanges.subscribe(c => {
                this.updatecontrolState();
            });
        }
    }

    setSelectionRange(selectionStart: number, selectionEnd: number): void {
        const input = this.el.nativeElement.querySelector('textarea');
        if (input.setSelectionRange) {
            setTimeout(() => {
                input.focus();
                input.setSelectionRange(selectionStart, selectionEnd);
            }, 100);
        } else if (input.createTextRange) {
            const range = input.createTextRange();
            range.collapse(true);
            range.moveEnd('character', selectionEnd);
            range.moveStart('character', selectionStart);
            range.select();
        }
    }

    updatecontrolState = () => {
        this.showError$.next(this.showError());
    };

    ngOnDestroy(): void {
        if (this.focusSubscription) {
            this.focusSubscription.unsubscribe();
        }
    }

    setCodeMirrorConfig(): void {
        this.config = {
            theme: 'ssms',
            mode: 'text/x-sql',
            lineNumbers: true,
            lineWrapping: true,
            foldGutter: true,
            gutters: ['CodeMirror-linenumbers', 'CodeMirror-foldgutter', 'CodeMirror-lint-markers'],
            autoCloseBrackets: true,
            matchBrackets: true,
            lint: true
        };
    }
}
