import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { TooltipModule } from 'shared/component/tooltip/tooltip.module';
import { ImageFullComponent } from './image-full.component';
import { ImageComponent } from './image.component';
import { ImageService } from './image.service';

@NgModule({
  imports: [
    CommonModule,
    TooltipModule,
    ButtonsModule
  ],
  declarations: [ImageComponent, ImageFullComponent],
  exports: [ImageComponent, ImageFullComponent],
  providers: [ImageService]
})
export class ImageModule { }
