import { ChangeDetectionStrategy, Component, ComponentFactoryResolver, EventEmitter, Input, OnInit, Output, ViewContainerRef } from '@angular/core';
import { ComponentData } from './component-loader-config';

@Component({
    selector: 'ipx-component-resolver',
    templateUrl: './ipx-component-resolver.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxComponentResolverComponent {
    @Input() set componentData(value: ComponentData) {
        if (value) {
            this.loadComponent(value);
        }
    }
    @Output() private readonly onViewInit = new EventEmitter<any>();

    constructor(private readonly componentFactoryResolver: ComponentFactoryResolver, private readonly vr: ViewContainerRef) { }

    loadComponent(data): void {
        if (data) {
            const componentFactory = this.componentFactoryResolver.resolveComponentFactory(data.component);

            const viewContainerRef = this.vr;
            viewContainerRef.clear();

            data.resolve().subscribe(obj => {
                const componentRef = viewContainerRef.createComponent(componentFactory);
                Object.assign(componentRef.instance, obj);
                componentRef.changeDetectorRef.detectChanges();
                this.onViewInit.emit(componentRef.instance);
            });
        }
    }
}
