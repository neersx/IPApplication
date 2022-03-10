import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { ReactiveFormsModule } from '@angular/forms';
import { SharedModule } from './../shared/shared.module';
import { AdHocDateComponent } from './adhoc-date.component';
import { AdhocDateService } from './adhoc-date.service';
import { FinaliseAdHocDateComponent } from './finalise-adhoc-date.component';

@NgModule({
    imports: [
      CommonModule,
      SharedModule,
      ReactiveFormsModule
    ],
    declarations: [FinaliseAdHocDateComponent, AdHocDateComponent],
    providers: [AdhocDateService],
    exports: [FinaliseAdHocDateComponent, AdHocDateComponent]
  })

export class DatesModule {}