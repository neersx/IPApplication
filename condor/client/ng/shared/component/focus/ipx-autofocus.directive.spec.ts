import { ChangeDetectionStrategy, Component } from '@angular/core';
import { async, ComponentFixture, fakeAsync, TestBed, tick } from '@angular/core/testing';
import { AutoFocusDirective } from './ipx-autofocus.directive';

@Component({
    template: `
    <input name="firstInput" label="first" />
    <div ipx-autofocus><input name="secondInput" label="second" /></div>`,
    changeDetection: ChangeDetectionStrategy.OnPush
})
class AutoFocusTestComponent {
    test: string;
}

// tslint:disable-next-line:only-arrow-functions
function isFocused(element: Element): boolean {
    return document.activeElement === element;
}

 describe('AutoFocusDirective', () => {
    let component: AutoFocusTestComponent;
    let fixture: ComponentFixture<AutoFocusTestComponent>;
    beforeEach(async(() => {
        TestBed.configureTestingModule({
            declarations: [AutoFocusDirective, AutoFocusTestComponent ]
        }).compileComponents().catch();
    }));
    beforeEach(async(() => {
        fixture = TestBed.createComponent(AutoFocusTestComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
    }));
    it('should set focus', fakeAsync(() => {
        const [first, second] = fixture.nativeElement.querySelectorAll('input') as Array<HTMLInputElement>;
        tick(100);
        fixture.detectChanges();
        expect(isFocused(first)).toBe(false);
        expect(isFocused(second)).toBe(true);
    }));
});