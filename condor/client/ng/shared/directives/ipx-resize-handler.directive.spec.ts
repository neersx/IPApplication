import { ChangeDetectionStrategy, Component, DebugElement } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { BusMock } from '../../mocks/bus.mock';
import { BusService } from './../../core/bus.service';
import { IpxResizeHandlerDirective } from './ipx-resize-handler.directive';

@Component({
    // tslint:disable-next-line:component-max-inline-declarations
    template: `<div ipx-resize-handler [resize-handler-type]="'Panel'">
                    <div style="height: 400px; width: 400px">
                    </div>
                </div>`,
    changeDetection: ChangeDetectionStrategy.OnPush
})
class TestIpxResizeHandlerComponent { }

describe('Directive: IpxResizeHandlerDirective', () => {
    let component: TestIpxResizeHandlerComponent;
    let fixture: ComponentFixture<TestIpxResizeHandlerComponent>;
    let directiveEl: DebugElement;
    let directiveInstance: any;

    beforeEach(() => {
        TestBed.configureTestingModule({
            declarations: [TestIpxResizeHandlerComponent, IpxResizeHandlerDirective],
            providers: [{ provide: BusService, useClass: BusMock }, {
                provide: RootScopeService,
                useClass: RootScopeServiceMock
            }]
        });
        fixture = TestBed.createComponent(TestIpxResizeHandlerComponent);
        component = fixture.componentInstance;
        directiveEl = fixture.debugElement.query(By.directive(IpxResizeHandlerDirective));
        directiveInstance = directiveEl.injector.get(IpxResizeHandlerDirective);
    });

    it('on window resize', () => {
        spyOn(directiveInstance, 'tryInitContainerSensor').and.returnValue({});
        const spyOnInitAdjustHeight = spyOn(directiveInstance, 'initAdjustHeight');
        window.dispatchEvent(new Event('resize'));
        fixture.detectChanges();
        expect(component).toBeDefined();
        expect(directiveEl).not.toBeNull();
        expect(spyOnInitAdjustHeight).toHaveBeenCalled();
    });
});