import { ChangeDetectionStrategy, Component, ComponentFactoryResolver, Input, OnInit, ViewChild } from '@angular/core';
import { AutoCompleteContract } from './autocomplete.contract';
import { ItemCodeDescKeyComponent } from './item-code-desc-key.component';
import { ItemCodeDescComponent } from './item-code-desc.component';
import { ItemCodeValueComponent } from './item-code-value.component';
import { ItemCodeComponent } from './item-code.component';
import { ItemDescComponent } from './item-desc.component';
import { ItemIdDescComponent } from './item-id-desc.component';
import { ItemNameDescComponent } from './item-name-desc.component';
import { TemplateHostDirective } from './template.host.directive';
import { TemplateType } from './template.type';

@Component({
    selector: 'dynamic-item-template',
    template: '<ng-template template-host></ng-template>',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class DynamicItemTemplateComponent implements OnInit {
    @Input() templateType: TemplateType;
    @Input() item: any;
    @Input() keyField: string;
    @Input() codeField: string;
    @Input() textField: string;
    @Input() searchValue: string;

    @ViewChild(TemplateHostDirective, { static: true }) templateHost: TemplateHostDirective;

    constructor(private readonly componentFactoryResolver: ComponentFactoryResolver) { }

    ngOnInit(): void {
        this.loadComponent();
    }

    loadComponent(): void {
        const component = this.componentResolver();

        const componentFactory = this.componentFactoryResolver.resolveComponentFactory(component);

        const viewContainerRef = this.templateHost.viewContainerRef;
        viewContainerRef.clear();

        const componentRef = viewContainerRef.createComponent(componentFactory);

        const componentInstance = componentRef.instance as AutoCompleteContract;
        componentInstance.item = this.item;
        componentInstance.keyField = this.keyField;
        componentInstance.codeField = this.codeField;
        componentInstance.textField = this.textField;
        componentInstance.searchValue = this.searchValue;
    }

    componentResolver(): any {
        switch (this.templateType) {
            case TemplateType.ItemCodeDesc: {
                return ItemCodeDescComponent;
            }
            case TemplateType.ItemCode: {
                return ItemCodeComponent;
            }
            case TemplateType.ItemDesc: {
                return ItemDescComponent;
            }
            case TemplateType.ItemIdDesc: {
                return ItemIdDescComponent;
            }
            case TemplateType.ItemNameDesc: {
                return ItemNameDescComponent;
            }
            case TemplateType.ItemCodeValue: {
                return ItemCodeValueComponent;
            }
            case TemplateType.ItemCodeDescKey: {
                return ItemCodeDescKeyComponent;
            }
            default:
                return ItemDescComponent;
        }
    }
}
