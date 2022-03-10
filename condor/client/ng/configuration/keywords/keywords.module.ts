import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { keywords } from './keywords-states';
import { KeywordsComponent } from './keywords.component';
import { KeywordsService } from './keywords.service';
import { MaintainKeywordsComponent } from './maintain-keywords/maintain-keywords.component';

@NgModule({
  declarations: [KeywordsComponent, MaintainKeywordsComponent],
  imports: [
    CommonModule,
    SharedModule,
    ButtonsModule,
    UIRouterModule.forChild({ states: [keywords] })
  ],
  providers: [
    KeywordsService
  ]
})
export class KeywordsModule { }
