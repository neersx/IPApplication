import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';

@Component({
  selector: 'ipx-inheritance-icon',
  templateUrl: './ipx-inheritance-icon.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxInheritanceIconComponent implements OnInit {
  readonly tooltipMap = {
    Full: 'Inheritance.FullyInherited',
    Partial: 'Inheritance.PartiallyInherited',
    InheritedOrDerived: 'Inheritance.InheritedOrDerived'
  };
  @Input() inheritanceLevel: string;
  @Input() tooltipPlacement: string;
  tooltip: string;

  ngOnInit(): void {
    this.tooltip = this.inheritanceLevel == null ? 'Inheritance.inherits' : this.tooltipMap[this.inheritanceLevel];
  }
}
