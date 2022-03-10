import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { SharedModule } from 'shared/shared.module';
import { SearchService } from '../screen-designer/case/search/search.service';
import { CreateChecklistComponent } from './maintenance/create-checklist/create-checklist.component';
import { ChecklistSearchComponent } from './search/checklist-search.component';
import { ChecklistSearchService } from './search/checklist-search.service';
import { CommonChecklistCharacteristicsComponent } from './search/common-characteristics/common-checklist-characteristics.component';
import { SearchByCaseComponent } from './search/search-by-case/search-by-case.component';
import { SearchByCharacteristicComponent } from './search/search-by-characteristics/search-by-characteristic.component';
import { SearchByCriteriaComponent } from './search/search-by-criteria/search-by-criteria.component';
import { SearchByQuestionComponent } from './search/search-by-question/search-by-question.component';

@NgModule({
    imports: [
        SharedModule,
        CommonModule
    ],
    declarations: [
        ChecklistSearchComponent,
        SearchByCharacteristicComponent,
        SearchByCaseComponent,
        SearchByCriteriaComponent,
        CreateChecklistComponent,
        SearchByQuestionComponent,
        CommonChecklistCharacteristicsComponent
    ],
    entryComponents: [
        ChecklistSearchComponent,
        SearchByCaseComponent,
        SearchByCriteriaComponent,
        CreateChecklistComponent,
        SearchByQuestionComponent,
        CommonChecklistCharacteristicsComponent
    ],
    providers: [
        ChecklistSearchService,
        SearchService
    ]
})
export class ChecklistConfigurationModule { }
