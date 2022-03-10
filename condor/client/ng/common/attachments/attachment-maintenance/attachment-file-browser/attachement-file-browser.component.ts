import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormControl } from '@angular/forms';
import { CancelEvent, FileInfo, FileRestrictions, RemoveEvent, SuccessEvent, UploadEvent } from '@progress/kendo-angular-upload';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType } from 'shared/component/grid/ipx-grid.models';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { AttachmentService } from '../../attachment.service';
import { AttachmentFileUploadComponent } from '../attachment-file-upload/attachment-file-upload.component';
import { AttachmentFileBrowserService } from './attachment-file-browser.service';

@Component({
  selector: 'app-attachement-file-browser',
  templateUrl: './attachement-file-browser.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AttachmentFileBrowserComponent implements OnInit {
  filePathControl: FormControl;
  hasSettings: boolean;
  treeLoading = false;
  gridOptions: IpxGridOptions;
  data = [];
  selectedFolderPath = '';
  selectedFileFullPath = '';
  selectedFile = '';
  fileUploadModalRef: BsModalRef;
  storageLocation = null;
  expandedKeys: Array<any> = [];
  selectedKeys: Array<any> = [];

  constructor(readonly bsModalRef: BsModalRef, private readonly cdr: ChangeDetectorRef, readonly service: AttachmentFileBrowserService, private readonly modalService: IpxModalService, private readonly attachmentService: AttachmentService) {

  }

  ngOnInit(): void {
    if (this.hasSettings) {
      this.treeLoading = true;
      this.service.getDirectoryFolders('')
        .subscribe((d: { folders: Array<any> }) => {
          this.data = d.folders;
          this.treeLoading = false;
          this.gridOptions = this.buildGridOptions();
          if (this.filePathControl.value) {
            this.setSelectedKeys();
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
    this.reloadFiles();
    this.attachmentService.getStorageLocation(this.selectedFolderPath).subscribe(es => {
      this.storageLocation = es;
      this.cdr.markForCheck();
    });
  };

  children = (node: any) => {
    return node.folders;
  };

  onRowSelectionChanged = (dataItem: any) => {
    this.selectedFile = dataItem.pathShortName;
    this.selectedFileFullPath = dataItem.fullPath;
  };

  select = () => {
    this.filePathControl.setValue(this.selectedFileFullPath);
    this.filePathControl.markAsDirty();
    this.bsModalRef.hide();
  };
  upload = () => {

    this.fileUploadModalRef = this.modalService.openModal(AttachmentFileUploadComponent, {
      animated: true,
      ignoreBackdropClick: true,
      backdrop: 'static',
      class: 'modal-l',
      initialState: {
        path: this.selectedFolderPath,
        extensions: this.storageLocation.allowedFileExtensions.split(',')
      }
    });

    this.fileUploadModalRef.content.onClose$.subscribe(
      (event: any) => {
        if (event) {
          this.refresh();
        }
      }
    );
  };

  refresh = () => {
    this.reloadFiles();
  };

  private readonly buildGridOptions = (): IpxGridOptions => {
    const options: IpxGridOptions = {
      sortable: false,
      showGridMessagesUsingInlineAlert: true,
      autobind: false,
      reorderable: false,
      pageable: false,
      enableGridAdd: false,
      selectable: {
        mode: 'single'
      },
      gridMessages: {
        noResultsFound: 'grid.messages.noItems',
        performSearch: 'caseview.caseDocumentManagementSystem.selectFolder'
      },
      read$: () => {
        return this.service.getDirectoryFiles(this.selectedFolderPath);
      },
      columns: [
        {
          title: 'caseview.attachments.maintenance.fileBrowser.name',
          field: 'pathShortName',
          width: 100,
          sortable: false
        },
        {
          title: 'caseview.attachments.maintenance.fileBrowser.dateModified',
          field: 'dateModified',
          defaultColumnTemplate: DefaultColumnTemplateType.date,
          width: 100,
          sortable: false
        },
        {
          title: 'caseview.attachments.maintenance.fileBrowser.type',
          field: 'type',
          width: 100,
          sortable: false
        },
        {
          title: 'caseview.attachments.maintenance.fileBrowser.size',
          field: 'size',
          width: 100,
          sortable: false
        }]
    };

    return options;
  };

  private readonly setSelectedKeys = () => {
    const originalFolderPath = this.filePathControl.value.substring(0, this.filePathControl.value.lastIndexOf('\\') + 1);
    let folderPath = originalFolderPath.toLowerCase();
    if (!folderPath.endsWith('\\')) {
      folderPath += '\\';
    }
    this.selectedKeys = [folderPath];
    const tokens = folderPath.split('\\').filter(_ => _);
    const expandedKeys = [];
    let key = '';
    tokens.forEach(token => {
      key = `${key}${token}\\`;
      expandedKeys.push(key);
    });
    this.expandedKeys = expandedKeys;
    this.selectedFolderPath = originalFolderPath;
    this.cdr.detectChanges();
    setTimeout(() => {
      this.gridOptions._search();
      this.cdr.detectChanges();
    }, 200);
  };

  private readonly reloadFiles = () => {
    this.selectedFile = '';
    this.selectedFileFullPath = '';
    this.gridOptions._search();
    this.cdr.detectChanges();
  };
}
