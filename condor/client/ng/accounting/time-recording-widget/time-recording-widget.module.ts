import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { SharedModule } from 'shared/shared.module';
import { TimeRecordingWidgetComponent } from './time-recording-widget.component';
import { TimerModalComponent } from './timer-modal/timer-modal.component';
import { TimerModalService } from './timer-modal/timer-modal.service';
import { TimerService } from './timer.service';

@NgModule({
   declarations: [
      TimeRecordingWidgetComponent,
      TimerModalComponent
   ],
   imports: [
      CommonModule,
      SharedModule
   ],
   entryComponents: [
      TimeRecordingWidgetComponent
   ],
   exports: [
      TimeRecordingWidgetComponent
   ],
   providers: [
      TimerService,
      TimerModalService
   ]
})
export class TimeRecordingWidgetModule { }