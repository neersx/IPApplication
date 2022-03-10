import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { StateService } from '@uirouter/core';
import { LocalSettings } from 'core/local-settings';
import { ScreenDesignerService } from '../../screen-designer.service';
import { InheritanceService } from './inheritance.service';

@Component({
  selector: 'ipx-inheritance',
  templateUrl: './inheritance.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class InheritanceComponent implements OnInit {
  selectedCriteriaId: string;
  treeNodes: any;
  keys: Array<string> = [];
  showSummary: boolean;
  @Input() viewData: any;

  constructor(readonly service: InheritanceService, readonly cdr: ChangeDetectorRef, readonly screenDesignerService: ScreenDesignerService, public $state: StateService, readonly localSettings: LocalSettings) {
  }

  ngOnInit(): void {
    this.service.getInheritance([this.viewData.id]).then(treeNodes => {
      this.treeNodes = treeNodes;
      this.expandAll();
      this.cdr.markForCheck();
    });
    this.showSummary = !!this.localSettings.keys.screenDesigner.inheritance.showSummary.getLocal;
  }

  beforeLevelUp = (): void => {
    this.screenDesignerService.popState();
  };

  expandAll = () => {
    this.treeNodes.trees.forEach((node, index) => {
      this.recursivelyExpandNode(node, index.toString());
      if (this.keys.indexOf(index.toString()) === -1) {
        this.keys = this.keys.concat(index.toString());
      }
    });
  };

  collapseAll = () => {
    this.keys = [];
  };

  onSelectionChange = (event: any) => {
    this.selectedCriteriaId = event.dataItem.id;
  };

  navigateToCriteria = (id: number) => {
    this.screenDesignerService.pushState({ id, stateName: 'screenDesignerCaseInheritance' });
    this.$state.go('screenDesignerCaseCriteria', { id, rowKey: this.viewData.rowKey });
  };

  private readonly recursivelyExpandNode = (child, prefix?: string) => {
    (child.items || []).forEach((node, index) => {
      const newPrefix = (prefix ? `${prefix}_${index}` : index.toString());
      if (this.keys.indexOf(newPrefix.toString()) === -1) {
        this.keys = this.keys.concat(newPrefix);
      }
      this.recursivelyExpandNode(node, newPrefix);
    });
  };

  isExpanded = (dataItem: any, index: string) => {
    return this.keys.indexOf(index) > -1;
  };

  handleCollapse(node): void {
    this.keys = this.keys.filter(k => k !== node.index);
  }

  handleExpand(node): void {
    if (this.keys.indexOf(node.index) === -1) {
      this.keys = this.keys.concat(node.index);
    }
  }

  allSelected = (): boolean => {
    return this.treeNodes && (this.keys.length >= this.treeNodes.totalCount);
  };

  noneSelected = (): boolean => {
    return this.keys.length === 0;
  };

  setStoreOnToggle(event: Event): void {
    this.localSettings.keys.screenDesigner.inheritance.showSummary.setLocal(event);
  }
}
