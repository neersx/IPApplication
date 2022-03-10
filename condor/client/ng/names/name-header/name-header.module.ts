import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { CasesCoreModule } from 'cases/core/cases.core.module';
import { PipesModule } from 'shared/pipes/pipes.module';
import { SharedModule } from 'shared/shared.module';
import { NameHeaderComponent } from './name-header.component';
import { NameHeaderService } from './name-header.service';

const components = [
    NameHeaderComponent
];
const providers = [
    NameHeaderService
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
export class NameHeaderModule { }
