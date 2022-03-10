import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { By } from '@angular/platform-browser';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { TranslatedServiceMock, TranslatePipeMock } from '../../../../../signin/src/app/mock/index.spec';
import { Translate } from '../../../../ajs-upgraded-providers/translate.mock';
import { IpxInlineDialogComponent } from '../../tooltip/ipx-inline-dialog/ipx-inline-dialog.component';
import { IpxMultiStateCheckboxComponent } from './ipx-multistate-checkbox.component';

describe('IpxCheckboxComponent', () => {
    let component: IpxMultiStateCheckboxComponent;
    let fixture: ComponentFixture<IpxMultiStateCheckboxComponent>;
    let inputEl: any;

    const translate: TranslatedServiceMock = new TranslatedServiceMock();
    beforeEach(() => {
        TestBed.configureTestingModule({
            imports: [
                FormsModule,
                PopoverModule.forRoot(),
                TranslateModule
            ],
            providers: [{ provide: TranslateService, useValue: translate }],
            declarations: [IpxMultiStateCheckboxComponent, IpxInlineDialogComponent, Translate, TranslatePipeMock]
        });
        fixture = TestBed.createComponent(IpxMultiStateCheckboxComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
        inputEl = fixture.debugElement.query(By.css('input')).nativeElement;
    });

    it('should initialize', () => {
        expect(component).toBeTruthy();
    });

    it('check input states', () => {
        expect(inputEl.checked).toBeFalsy();

        inputEl.click();
        fixture.detectChanges();
        expect(inputEl.checked).toBeTruthy();
    });

    it('should modelChange', () => {
        spyOn(component.onChange, 'emit');
        let model = { status: 1 };
        component.modelChange(model);
        expect(component.onChange.emit).toHaveBeenLastCalledWith(2);
        model = { status: 2 };
        component.modelChange(model);
        expect(component.onChange.emit).toHaveBeenLastCalledWith(0);
        model = { status: 0 };
        component.modelChange(model);
        expect(component.onChange.emit).toHaveBeenLastCalledWith(1);
    });

});