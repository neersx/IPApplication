import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { SharedModule } from 'shared/shared.module';
import { QuicksearchHighlight } from './quick-search-highlight.pipe';
import { QuickSearchComponent } from './quick-search.component';
import { QuickSearchService } from './quick-search.service';

@NgModule({
  declarations: [QuickSearchComponent, QuicksearchHighlight],
  imports: [
    CommonModule,
    HttpClientModule,
    FormsModule,
    SharedModule
  ],
  providers: [QuickSearchService],
  exports: [QuickSearchComponent, QuicksearchHighlight]
})
export class QuickSearchModule { }
