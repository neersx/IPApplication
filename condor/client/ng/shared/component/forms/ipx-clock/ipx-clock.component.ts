import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, NgZone, OnChanges, OnDestroy, OnInit, Optional, Self, SimpleChanges } from '@angular/core';
import { NgControl } from '@angular/forms';
import { interval } from 'rxjs';
import { ElementBaseComponent } from 'shared/component/forms/element-base.component';

export enum clockStates {
    Running,
    Pause,
    Stop
}

@Component({
    selector: 'ipx-clock',
    template: '<span *ngIf="!start">{{ time | date: format }}</span><span *ngIf="!!start" id="clockTimeSpan">{{ time | durationFormat: true }}</span>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxClockComponent extends ElementBaseComponent<Date> implements OnInit, OnDestroy, OnChanges {
    @Input() start: Date;
    @Input() elapsedTime?: boolean;
    @Input() clockState?: clockStates;
    startTime?: number;
    @Input() format: string;
    tick: any;
    time: number;

    constructor(@Self() @Optional() public control: NgControl, public el: ElementRef, private readonly cdRef: ChangeDetectorRef,
        private readonly zone: NgZone) {
        super(control, el, cdRef);
    }

    private _initValues(): void {
        if (!!this.start) {
            this.startTime = new Date(this.start).getTime();
            this.time = (Date.now() - this.startTime) / 1000;
        } else {
            this.time = Date.now();
        }
    }

    resetTimer(newStart: Date): void {
        this.start = newStart;
        this._initValues();
        this.cdRef.markForCheck();
    }

    ngOnChanges(changes: SimpleChanges): void {
        this.cdRef.detectChanges();
    }

    ngOnInit(): void {
        this._initValues();
        this.format = !this.format ? 'HH:mm:ss' : this.format;
        this.zone.runOutsideAngular(() => {
            this.tick = interval(1000)
                .subscribe(x => {
                    this.time = !!this.startTime ? ((Date.now() - this.startTime) / 1000) : Date.now();
                    this.cdRef.detectChanges();
                });
        });
    }

    ngOnDestroy(): void {
        this.tick.unsubscribe();
    }
}