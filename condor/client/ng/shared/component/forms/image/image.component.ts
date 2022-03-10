import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnChanges, OnInit, SimpleChanges } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { ImageFullComponent } from './image-full.component';
import { ImageService } from './image.service';

@Component({
  selector: 'ipx-image',
  templateUrl: './image.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ImageComponent implements OnInit, OnChanges {
  @Input() imageKey: number;
  @Input() maxWidth?: number;
  @Input() maxHeight?: number;
  @Input() isThumbnail: boolean;
  @Input() isClickable: boolean;
  @Input() isFullImage: boolean;
  @Input() imageTitle: string;
  @Input() itemKey: number;
  @Input() type: 'case' | 'name';
  image: any;
  imageSrc: string;
  modalRef: BsModalRef;

  constructor(
    private readonly service: ImageService,
    private readonly modalService: IpxModalService,
    private readonly cdRef: ChangeDetectorRef
  ) { }

  ngOnInit(): void {
    this.loadImage();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes.imageKey && changes.imageKey.currentValue && this.itemKey) {
      this.loadImage();
    }
  }

  private readonly loadImage = (): void => {
    if (!this.isThumbnail && !this.isFullImage) {
      this.maxWidth = window.innerWidth - 40;
      this.maxHeight = window.innerHeight - 40;
    }

    this.service
      .getImage(this.itemKey, this.type, this.imageKey, this.maxWidth, this.maxHeight)
      .subscribe((data: any) => {
        this.image = data.image;
        if (this.image) {
          this.imageSrc = 'data:image/PNG;base64' + ',' + this.image;
          this.cdRef.markForCheck();
        }
      });
  };

  mouseClick = (): any => {
    const initialState = {
      itemKey: this.itemKey,
      imageKey: this.imageKey,
      imageTitle: this.imageTitle,
      type: this.type
    };
    this.modalRef = this.modalService.openModal(ImageFullComponent, {
      animated: false,
      backdrop: true,
      class: 'modal-xl',
      initialState
    });

    return this.modalRef;
  };
}
