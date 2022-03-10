import { NgModule } from '@angular/core';
import { SharedModule } from 'shared/shared.module';
import { TimeRecordingQueryComponent } from './time-recording-query.component';
import { TimeSearchService } from './time-search.service';
import { UpdateNarrativeComponent } from './update-narrative/update-narrative.component';

@NgModule({
   imports: [
      SharedModule
   ],
   declarations: [
      TimeRecordingQueryComponent,
      UpdateNarrativeComponent,
      UpdateNarrativeComponent
   ],
   exports: [
      TimeRecordingQueryComponent
   ],
   providers: [
      TimeSearchService
   ]
})
export class TimeRecordingQueryModule { }