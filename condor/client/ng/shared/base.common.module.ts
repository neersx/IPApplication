import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';
import { TooltipModule } from 'ngx-bootstrap/tooltip';

const modules = [CommonModule, TranslateModule, FormsModule, ReactiveFormsModule, TooltipModule];

@NgModule({
    imports: modules,
    exports: modules
})
export class BaseCommonModule { }
