import { DatePipe } from '@angular/common';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Subscriber } from 'rxjs';
import { PipesModule } from 'shared/pipes/pipes.module';
import { IpxClockComponent } from './ipx-clock.component';

describe('ClockComponentComponent', () => {
    let component: IpxClockComponent;
    let fixture: ComponentFixture<IpxClockComponent>;

    beforeEach(() => {
        TestBed.configureTestingModule({
            imports: [PipesModule],
            providers: [{ provide: DatePipe, useClass: DatePipe }],
            declarations: [IpxClockComponent]
        });
        fixture = TestBed.createComponent(IpxClockComponent);
        component = fixture.componentInstance;
    });

    describe('initialising', () => {
        it('should create', () => {
            fixture.detectChanges();
            expect(component).toBeTruthy();
        });
        it('should set the time value', () => {
            fixture.detectChanges();
            expect(component.startTime).not.toBeDefined();
            expect(component.time).toBeDefined();
            expect(component.tick).toEqual(expect.any(Subscriber));
        });
        it('should set the time based on start time', () => {
            const start = new Date();
            component.start = start;
            fixture.detectChanges();
            expect(component.startTime).toBe(new Date(start).getTime());
            expect(component.time).toBeDefined();
            expect(component.format).toBe('HH:mm:ss');
            expect(component.tick).toEqual(expect.any(Subscriber));
        });
    });

    describe('resetting', () => {
        it('resets to the new start', () => {
            const start = new Date();
            start.setHours(10);
            const newStart = start;
            newStart.setMinutes(55);
            component.start = start;
            component.format = 'hh:mm';
            fixture.detectChanges();
            expect(component.startTime).toBe(new Date(start).getTime());
            expect(component.time).toBeDefined();
            expect(component.tick).toEqual(expect.any(Subscriber));

            component.resetTimer(newStart);
            expect(component.start).toBe(newStart);
            expect(component.startTime).toBe(new Date(newStart).getTime());
            expect(component.time).toBeDefined();
            expect(component.format).toBe('hh:mm');
            expect(component.tick).toEqual(expect.any(Subscriber));
        });
    });
});