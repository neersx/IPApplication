import { ChangeDetectionStrategy, Component, DebugElement } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { TransitionService } from '@uirouter/core';
import { TransitionServiceMock } from 'mocks/transition-service.mock';
import { IpxConfirmBeforeRouteChangeDirective } from './ipx-confirm-before-route-change.directive';

@Component({
    // tslint:disable-next-line:component-max-inline-declarations
    template: `<div [ipxConfirmBeforeRouteChange]="isPageDirty">
                </div>`,
    changeDetection: ChangeDetectionStrategy.OnPush
})
class TestIpxConfirmBeforeRouteChangeComponent {
    isPageDirty: any;
}

describe('Directive: IpxConfirmBeforeRouteChangeDirective', () => {
    let component: TestIpxConfirmBeforeRouteChangeComponent;
    let fixture: ComponentFixture<TestIpxConfirmBeforeRouteChangeComponent>;
    let directiveEl: DebugElement;
    let directiveInstance: any;

    beforeEach(() => {
        TestBed.configureTestingModule({
            declarations: [TestIpxConfirmBeforeRouteChangeComponent, IpxConfirmBeforeRouteChangeDirective],
            providers: [
                { provide: TransitionService, useClass: TransitionServiceMock}]
        });
        fixture = TestBed.createComponent(TestIpxConfirmBeforeRouteChangeComponent);
        component = fixture.componentInstance;
        directiveEl = fixture.debugElement.query(By.directive(IpxConfirmBeforeRouteChangeDirective));
        directiveInstance = directiveEl.injector.get(IpxConfirmBeforeRouteChangeDirective);
    });

    it('show confirm dlg when form is dirty', () => {
        component.isPageDirty = jest.fn(() => true);
        const windowConfirmSpy = window.confirm = jest.fn().mockReturnValue(true);
        fixture.detectChanges();
        directiveInstance.canRouteChange();
        expect(component).toBeDefined();
        expect(directiveEl).not.toBeNull();
        expect(windowConfirmSpy).toHaveBeenCalled();
    });

    it('should call to deregister when the component is destroyed', () => {
        directiveInstance.deregister = 'somethingButNull';
        const spy  = directiveInstance.deregister = jest.fn();
        directiveInstance.ngOnDestroy();
        expect(spy).toHaveBeenCalled();
    });
});