
import { ChangeDetectorRefMock, ElementRefTypeahedMock, NgControl } from 'mocks';
import { IpxTextFieldComponent } from './ipx-text-field.component';
describe('IpxTextFieldComponent', () => {
    let component: IpxTextFieldComponent;
    const element = new ElementRefTypeahedMock();
    const ngControl = new NgControl();
    beforeEach(() => {
        component = new IpxTextFieldComponent(ngControl as any, element as any,
            ChangeDetectorRefMock as any);
    });

    it('should initialize ipx typeahead', () => {
        expect(component).toBeTruthy();
    });

    it('should set Code Mirror Config', () => {
        component.setCodeMirrorConfig();
        expect(component.config).toBeTruthy();
        expect(component.config).toEqual({ autoCloseBrackets: true, foldGutter: true, gutters: ['CodeMirror-linenumbers', 'CodeMirror-foldgutter', 'CodeMirror-lint-markers'], lineNumbers: true, lineWrapping: true, lint: true, matchBrackets: true, mode: 'text/x-sql', theme: 'ssms' });
    });
    it('should subscribe to OnFocus and setfocus on textarea or input', () => {
        component.ngOnInit();
        const selectedElem = { focus: jest.fn() };
        element.nativeElement.querySelector = jest.fn().mockReturnValue(selectedElem);

        component.onFocus.emit();
        expect(element.nativeElement.querySelector).toHaveBeenCalled();
        expect(element.nativeElement.querySelector.mock.calls[0][0].includes('input')).toBeTruthy();
        expect(element.nativeElement.querySelector.mock.calls[0][0].includes('textarea')).toBeTruthy();
        expect(selectedElem.focus).toHaveBeenCalled();
    });

    it('should call updatecontrolState', () => {
        component.updatecontrolState();
        component.showError$.subscribe(error => {
            expect(error).toBe(false);
        });
    });

    it('should update decimal value on change', () => {
        component.decimalPlaces = 4;
        const event = {
            target: {
                value: '12'
            }
        };
        component.change(event);
        expect(event.target.value).toBe('12.0000');
    });

    it('should write value with correct decimal numbers', () => {
        component.cdr = {
            markForCheck: jest.fn(),
            detach: jest.fn(),
            detectChanges: jest.fn(),
            checkNoChanges: jest.fn(),
            reattach: jest.fn()
        };
        component.decimalPlaces = 4;
        component.writeValue('12.5');
        expect(component.value).toBe('12.5000');
        expect(component.cdr.markForCheck).toBeCalled();
    });
});
