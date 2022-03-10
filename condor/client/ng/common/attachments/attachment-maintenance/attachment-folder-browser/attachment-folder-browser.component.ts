import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { FormControl } from '@angular/forms';
import { SelectableSettings, TreeViewComponent } from '@progress/kendo-angular-treeview';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { AttachmentService } from '../../attachment.service';
import { AttachmentFileBrowserService } from '../attachment-file-browser/attachment-file-browser.service';

@Component({
  selector: 'ipx-attachment-folder-browser',
  templateUrl: './attachment-folder-browser.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AttachmentFolderBrowserComponent implements OnInit {
  selection: SelectableSettings = { mode: 'single' };
  filePathControl: FormControl;
  expandedKeys: Array<any> = [];
  selectedKeys: Array<any> = [];
  hasSettings: boolean;
  treeLoading = false;
  data = [];
  selectedFolderPath = '';
  fileUploadModalRef: BsModalRef;
  storageLocation = null;

  constructor(readonly bsModalRef: BsModalRef, private readonly cdr: ChangeDetectorRef, readonly service: AttachmentFileBrowserService, private readonly modalService: IpxModalService, private readonly attachmentService: AttachmentService) {

  }

  ngOnInit(): void {
    if (this.hasSettings) {
      this.treeLoading = true;
      this.service.getDirectoryFolders('')
        .subscribe((d: { folders: Array<any> }) => {
          this.data = d.folders;
          this.treeLoading = false;
          this.selectedFolderPath = this.filePathControl.value;
          if (this.selectedFolderPath) {
            let folderPath = this.selectedFolderPath.toLowerCase();
            if (!folderPath.endsWith('\\')) {
              folderPath += '\\';
            }
            this.selectedKeys = [folderPath];
            const tokens = this.selectedFolderPath.toLowerCase().split('\\').filter(_ => _);
            const expandedKeys = [];
            let key = '';
            tokens.forEach(token => {
              key = `${key}${token}\\`;
              expandedKeys.push(key);
            });
            this.expandedKeys = expandedKeys;
          }
          this.cdr.detectChanges();
        });
    }
  }

  hasChildren = (node: any): boolean => {
    return node.hasSubfolders;
  };

  cancel = (): void => {
    this.bsModalRef.hide();
  };

  handleSelection = (node: any): void => {
    this.selectedFolderPath = node.dataItem.fullPath;
  };

  children = (node: any) => {
    return node.folders;
  };

  select = () => {
    this.filePathControl.setValue(this.selectedFolderPath);
    this.filePathControl.markAsDirty();
    this.bsModalRef.hide();
  };
}
