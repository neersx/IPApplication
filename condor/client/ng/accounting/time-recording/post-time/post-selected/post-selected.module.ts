import { NgModule } from '@angular/core';
import { SharedModule } from 'shared/shared.module';
import { PostSelectedComponent } from './post-selected.component';

@NgModule({
    imports: [
        SharedModule
    ],
    declarations: [
        PostSelectedComponent
    ],
    exports: [
        PostSelectedComponent
    ]
})
export class PostSelectedModule {

}