import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, Renderer2, ViewChild } from '@angular/core';
import { FileRestrictions, RemoveEvent, SelectEvent, SuccessEvent, UploadEvent } from '@progress/kendo-angular-upload';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';

@Component({
  selector: 'app-attachment-file-upload',
  templateUrl: './attachment-file-upload.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AttachmentFileUploadComponent implements OnInit, AfterViewInit {
  @ViewChild('upload', { static: true }) fileUpload: any;
  path: string;
  extensions: Array<string>;
  fileRestrictions: FileRestrictions = {};
  fileUploaded = false;
  onClose$ = new Subject();
  pendingFileCount = 0;
  constructor(readonly bsModalRef: BsModalRef, private readonly cdr: ChangeDetectorRef, private readonly renderer: Renderer2) {
  }

  ngOnInit(): void {
    this.fileRestrictions = {
      allowedExtensions: this.extensions,
      maxFileSize: 4194304
    };

    this.cdr.markForCheck();
  }

  ngAfterViewInit(): void {
    const extensions = '.' + this.extensions.join(',.');
    this.renderer.setAttribute(this.fileUpload.fileSelectButton.nativeElement.children[0], 'accept', extensions);
  }

  cancel = (): void => {
    this.onClose$.next(this.fileUploaded);
    this.bsModalRef.hide();
  };

  saveFilesApi = 'api/attachment/uploadFiles';
  onUpload = (ev: UploadEvent): void => {
    ev.data = {
      folderPath: this.path
    };
  };

  onError(): void {
    this.cdr.markForCheck();
  }

  onComplete = (): void => {
    this.fileUploaded = true;
    this.cdr.markForCheck();
  };

  onUploadButtonClick = (upload: any) => {
    upload.uploadFiles();
  };

  onClearButtonClick = (upload: any) => {
    this.pendingFileCount = 0;
    upload.clearFiles();
  };

  onSelectEvent = (e: SelectEvent) => {
    this.pendingFileCount += e.files.filter(f => f.validationErrors == null).length;
  };

  onUploadEvent = () => {
    this.pendingFileCount = 0;
  };

  onRemoveEvent = (e: RemoveEvent) => {
    if (this.pendingFileCount > 0) {
      if (e.files.length === 1 && e.files[0].validationErrors == null && e.files[0].state !== 0) {
        this.pendingFileCount -= 1;
      }
    }
  };
}
