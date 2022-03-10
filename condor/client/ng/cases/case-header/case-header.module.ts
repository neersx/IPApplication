import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { CasesCoreModule } from 'cases/core/cases.core.module';
import { PipesModule } from 'shared/pipes/pipes.module';
import { SharedModule } from 'shared/shared.module';
import { CaseHeaderComponent } from './case-header.component';
import { CaseHeaderService } from './case-header.service';

const components = [
    CaseHeaderComponent
];
const providers = [
    CaseHeaderService
];

@NgModule({
    imports: [
        SharedModule,
        PipesModule,
        CasesCoreModule,
        CommonModule
    ],
    exports: [
        ...components
    ],
    declarations: [
        ...components
    ],
    providers: [
        ...providers
    ],
    entryComponents: [
        ...components
    ]
})
export class CaseHeaderModule { }
