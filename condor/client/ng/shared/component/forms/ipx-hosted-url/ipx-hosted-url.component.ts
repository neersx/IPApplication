import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { WindowParentMessage, WindowParentMessagingService } from 'core/window-parent-messaging.service';

@Component({
  selector: 'ipx-hosted-url',
  templateUrl: './ipx-hosted-url.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxHostedUrlComponent implements OnInit {

  @Input() dataField: any;
  @Input() key: string;
  @Input() linkArgs: Array<string>;
  @Input() linkType: string;
  @Input() action: string;
  @Input() description: string;
  @Input() programId: string;
  @Input() xmlFilterCriteria: string;
  @Input() showLink: boolean;
  @Input() decimalPlaces: number;
  @Input() currencyCode: string;
  @Input() format: string;
  // @Input() columnInfo: any;
  @Input() debtorAction: number;
  @Input() isInherited: boolean;
  isHosted = false;
  actionData: WindowParentMessage;
  hostProgramId: string;
  isHyperLink: boolean;
  constructor(private readonly rootscopeService: RootScopeService, private readonly windowParentMessagingService: WindowParentMessagingService) { }

  ngOnInit(): void {
    // this.isHyperLink = (this.action !== 'IconImageKey' && this.action !== 'ROIMoreInfo' && this.action !== 'SupplierRestrictionIcon') && this.key && this.showLink;
    this.isHosted = this.rootscopeService.isHosted;
    this.hostProgramId = this.rootscopeService.rootScope.hostedProgramId;
  }

  // isCurrencyColumn = () => {
  //   return this.columnInfo && (this.columnInfo.format === 'Currency' || this.columnInfo.format === 'Local Currency');
  // };

  buildLink = (): void => {
    if (this.action && this.key) {
      const mappedArgs = this.dataField
        ? this.linkArgs.map((mappedArg, index) => {
          // tslint:disable-next-line: strict-boolean-expressions
          return this.dataField.link[mappedArg] || '';
        })
        : this.linkArgs;

      const args = [this.linkType, ...mappedArgs];
      if (this.requiresXmlFilterCriteria(this.linkType)) {
        args.push(this.xmlFilterCriteria);
      }

      this.actionData = { args };
    }
  };

  requiresXmlFilterCriteria = (linkType: string): boolean => {
    return linkType === 'CaseOrNameWIPItems';
  };

  postMessage = (): void => {
    this.buildLink();
    this.windowParentMessagingService.postNavigationMessage(this.actionData);
  };
}