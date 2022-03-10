import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { AppContextService } from 'core/app-context.service';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { IpxModalService } from 'shared/component/modal/modal.service';
import * as _ from 'underscore';
import { AttachmentMaintenanceFormComponent } from '../../attachments/attachment-maintenance/attachment-maintenance-form/attachment-maintenance-form.component';
import { AttachmentService } from '../../attachments/attachment.service';
import { GenerateDocumentErrorsComponent } from './generate-document-errors/generate-document-errors.component';
import { GenerateDocumentService } from './generate-document.service';
@Component({
  selector: 'ipx-generate-document',
  templateUrl: './generate-document.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class GenerateDocumentComponent implements OnInit {
  @ViewChild('maintenanceForm', { static: false }) maintenanceForm: AttachmentMaintenanceFormComponent;
  vm: any;
  isCase: boolean;
  caseKey: number;
  nameKey: number;
  isWord: boolean;
  isHosted: boolean;
  canAddAttachments: boolean;
  translationPrefix: string;
  irn: string;
  nameCode: string;
  modalRef: BsModalRef;
  fileBrowserModalRef: BsModalRef;
  isE2e: any;
  hasSettings: boolean;
  document: any;
  documentId$ = new BehaviorSubject(null);
  addAsAttachment = false;
  hasValidChanges$ = new BehaviorSubject(false);
  maintenanceViewData: any;
  baseType: string;
  @Input() modalTitle: string;
  documentAttachmentsDisabled = false;
  inprodocUri$ = new BehaviorSubject(null);
  errors: any = null;
  constructor(readonly bsModalRef: BsModalRef,
    private readonly service: GenerateDocumentService,
    private readonly attachmentService: AttachmentService,
    private readonly cdr: ChangeDetectorRef,
    private readonly messagingService: WindowParentMessagingService,
    private readonly rootScopeService: RootScopeService,
    private readonly appContextService: AppContextService,
    private readonly modalService: IpxModalService) {
    this.vm = {
      docGenTemplatesExtendedQuery: this.docGenTemplatesExtendedQuery.bind(this)
    };
  }

  ngOnInit(): void {
    this.initSettings();
    this.attachmentService.attachmentMaintenanceView$(this.baseType, this.caseKey || this.nameKey, {}).subscribe(
      (result) => {
        this.documentAttachmentsDisabled = result.documentAttachmentsDisabled || false;
        if (result.documentAttachmentsDisabled === true) {
          this.addAsAttachment = false;
        }
        this.canAddAttachments = result.canAddAttachments;
        this.hasSettings = result.hasAttachmentSettings;
        this.maintenanceViewData = {
          ...result,
          id: this.caseKey || this.nameKey,
          baseType: this.baseType,
          isAdHocGeneration: true,
          defaultFileName: this.isWord ? 'attach.doc' : 'attach.pdf'
        };
        this.cdr.markForCheck();
      });
  }

  onDocumentChange = () => {
    if (this.document != null && !this.documentAttachmentsDisabled) {
      this.addAsAttachment = this.document.addAttachment === true ? true : this.document.addAttachment === false ? false : this.addAsAttachment;
    }
    this.cdr.markForCheck();
    this.documentId$.next(this.document != null ? this.document.key : null);
  };

  updateStatus = (event: any) => {
    this.hasValidChanges$.next(event);
  };

  generateAndSave = (): void => {
    if (!this.document) {
      return;
    }

    const key = this.isCase ? this.caseKey : this.nameKey;
    const entryPoint = this.isCase ? this.irn : this.nameCode;
    const callerType = this.isCase ? 'CaseView' : 'NameView';
    let saveFileLocation: string;
    let directoryName: string;
    let fileName: string;
    if (this.addAsAttachment) {
      directoryName = this.maintenanceForm.formGroup.value.filePath;
      fileName = this.maintenanceForm.formGroup.value.fileName;
      saveFileLocation = directoryName.endsWith('\\') ? directoryName + fileName : directoryName + '\\' + fileName;
    }

    this.service.getDataForAdhocDoc$(callerType, key, this.document.key, this.addAsAttachment || false).subscribe((resp) => {
      if (resp) {
        const generateCall: Observable<any> = this.isWord ? this.generate(resp, entryPoint, saveFileLocation)
          : this.service.generateAndSavePdf$(callerType, key, this.document.key, this.document.value, this.document.template, directoryName, fileName, entryPoint);
        generateCall.subscribe(generationResult => {
          if (this.isWord) {
            if (generationResult === 0 || generationResult === -3) {
              this.saveAndClose();
            }
          } else {
            if (generationResult.errors && generationResult.errors.length !== 0) {
              this.errors = generationResult.errors;
              this.cdr.markForCheck();
              this.modalService.openModal(GenerateDocumentErrorsComponent, {
                animated: false,
                ignoreBackdropClick: true,
                backdrop: 'static',
                class: 'modal-xl',
                initialState: {
                  errors: this.errors,
                  documentName: this.document.value
                }
              });
            }
            if (generationResult.isSuccess) {
              const url = `${window.location.pathname}/api/attachment/${this.isCase ? 'case' : 'name'}/${key}/document/get-pdf?fileKey=${generationResult.fileIdentifier}`;
              this.saveAndClose();
              if (window.navigator && window.navigator.msSaveOrOpenBlob) {
                window.location.href = url;
              } else {
                window.open(url, '_blank');
              }
            }
          }
        });
      }
    });
  };

  private docGenTemplatesExtendedQuery(query: any): any {
    const extended = _.extend({}, query, {
      options: JSON.stringify({
        InproDocOnly: this.isWord,
        pdfOnly: !this.isWord,
        caseKey: this.caseKey && this.isCase ? this.caseKey : null,
        nameKey: this.nameKey && !this.isCase ? this.nameKey : null
      })
    });

    return extended;
  }
  private readonly initSettings = () => {
    this.translationPrefix = this.isWord ? 'documentGeneration.generateWord.' : 'documentGeneration.generatePdf.';
    this.baseType = this.caseKey != null ? 'case' : this.nameKey != null ? 'name' : 'activity';
    this.isHosted = this.rootScopeService.isHosted;
    if (!this.isHosted) {
      this.modalTitle = this.translationPrefix + 'title';
    }
  };

  private readonly saveAndClose = () => {
    if (!this.errors) {
      if (this.addAsAttachment || this.hasValidChanges$.getValue()) {
        setTimeout(() => {
          this.maintenanceForm.save();
        }, 100);
      } else {
        this.onClose();
      }
    }
  };

  private generate(resp: any, entryPoint: string, saveFileLocation: string): Observable<any> {
    const inprodocArgs: any = ((my: any) => {
      let _current = '';
      my.add = (k, v) => {
        _current += (!v || v === '') ? '' : (' ' + k + '"' + v + '"');

        return inprodocArgs;
      };
      my.build = () => {
        return 'inprodoc:' + btoa(_current);
      };

      return my;
    })({});

    const cmd = inprodocArgs
      .add('-t', this.document.template)
      .add('-n', resp.networkTemplatesPath)
      .add('-l', resp.localTemplatesPath)
      .add('-e', entryPoint)
      .add('-s', saveFileLocation)
      .build();
    if (this.appContextService.isE2e && this.isE2e) {
      window.alert(cmd);
    } else {
      window.location = cmd;
    }

    return of(0);
  }

  onClose(): void {
    this.messagingService.postLifeCycleMessage({ action: 'onNavigate', target: 'generateDocument', payload: true }, () => {
      this.bsModalRef.hide();
    });
  }
}
