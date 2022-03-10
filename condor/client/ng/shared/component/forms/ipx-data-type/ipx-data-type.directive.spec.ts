import { DebugElement } from '@angular/core';
import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { FormControl, FormsModule } from '@angular/forms';
import { By } from '@angular/platform-browser';
import { TranslateFakeLoader, TranslateLoader, TranslateModule, TranslateService } from '@ngx-translate/core';
import { DataTypeExampleComponent } from 'dev/dataType/datatype-example.component';
import { CodemirrorModule } from 'ng2-codemirror';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { IpxHoverHelpComponent } from 'shared/component/tooltip/ipx-hover-help/ipx-hover-help.component';
import { IpxInlineDialogComponent } from 'shared/component/tooltip/ipx-inline-dialog/ipx-inline-dialog.component';
import { IpxTextFieldComponent } from '../ipx-text-field/ipx-text-field.component';
import { DataTypeDirective } from './ipx-data-type.directive';
describe('component: TestComponent', () => {
    let component: DataTypeExampleComponent;
    let fixture: ComponentFixture<DataTypeExampleComponent>;
    let directiveEl: DebugElement;
    let directiveInstance: any;
    beforeEach(() => {
        TestBed.configureTestingModule({
            imports: [FormsModule, TooltipModule.forRoot(), PopoverModule, CodemirrorModule,
                TranslateModule.forRoot({
                    loader: {
                        provide: TranslateLoader,
                        useClass: TranslateFakeLoader
                    }
                })],
            declarations: [DataTypeExampleComponent, DataTypeDirective, IpxTextFieldComponent, IpxInlineDialogComponent, IpxHoverHelpComponent],
            providers: [
                TranslateService
            ]
        });
        fixture = TestBed.createComponent(DataTypeExampleComponent);
        component = fixture.componentInstance;
        directiveEl = fixture.debugElement.query(By.directive(DataTypeDirective));
        directiveInstance = directiveEl.injector.get(DataTypeDirective);
        fixture.detectChanges();
        component.dataTypeValue = 10;
    });
    it('should create the app', () => {
        expect(component).toBeTruthy();
        expect(directiveEl).not.toBeNull();
    });
    it('should validate', async(() => {
        expect(component.dataTypeValue).toBe(10);
    }));
    it('should fire the any event', async(() => {
        const input = fixture.debugElement.query(By.css('[name=datatype]')).nativeElement;
        fixture.detectChanges();
        const event = new KeyboardEvent('keypress', {
            key: '12'
        });
        input.dispatchEvent(event);
        fixture.detectChanges();
    }));
    it('should fire the valid function for decimal datatype positive and negative test', async(() => {
        const control = new FormControl('input');
        control.setValue('text');
        directiveInstance.dataType = 'decimal';
        expect(directiveInstance.validate(control)).toEqual({ decimal: true });
        const control2 = new FormControl('input');
        control2.setValue('123.5');
        expect(directiveInstance.validate(control2)).toEqual({});
    }));
    it('should fire the valid function for integer datatype positive and negative test', async(() => {
        const control = new FormControl('input');
        control.setValue('text');
        directiveInstance.dataType = 'integer';
        expect(directiveInstance.validate(control)).toEqual({ integer: true });
        const control2 = new FormControl('input');
        control2.setValue('123');
        expect(directiveInstance.validate(control2)).toEqual({});
    }));
    it('should fire the valid function for positiveinteger datatype positive and negative test', async(() => {
        const control = new FormControl('input');
        control.setValue('text');
        directiveInstance.dataType = 'positiveinteger';
        expect(directiveInstance.validate(control)).toEqual({ positiveinteger: true });
        const control2 = new FormControl('input');
        control2.setValue('123');
        expect(directiveInstance.validate(control2)).toEqual({});
    }));

    it('should fire the valid function for nonnegativeinteger datatype positive and negative test', async(() => {
        const control = new FormControl('input');
        control.setValue('-123');
        directiveInstance.dataType = 'nonnegativeinteger';
        expect(directiveInstance.validate(control)).toEqual({ nonnegativeinteger: true });
        const control2 = new FormControl('input');
        control2.setValue('123');
        expect(directiveInstance.validate(control2)).toEqual({});
    }));

    it('should fire the valid function for positive decimal datatype and negative decimal test', async(() => {
        const control = new FormControl('input');
        control.setValue('-12.5');
        directiveInstance.dataType = 'positivedecimal';
        expect(directiveInstance.validate(control)).toEqual({ decimal: true });
        const control2 = new FormControl('input');
        control2.setValue('12.5');
        expect(directiveInstance.validate(control2)).toEqual({});
    }));
});