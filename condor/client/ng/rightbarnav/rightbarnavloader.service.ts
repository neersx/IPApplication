import { ComponentFactoryResolver, Inject, Injectable } from '@angular/core';
import { QuickNavModel } from './rightbarnav.service';

@Injectable()
export class RightBarNavLoaderService implements IQuicknavLoader {
    factoryResolver: any;
    rootViewContainer: any;
    constructor(@Inject(ComponentFactoryResolver) factoryResolver) {
        this.factoryResolver = factoryResolver;
    }

    setRootViewContainerRef = (viewContainerRef) => {
        this.rootViewContainer = viewContainerRef;
    };

    load(item: QuickNavModel): void {
        if (item.options.resolve) {
            item.options.resolve.viewData()
                .subscribe((data: any) => {
                    this.render(item, data);
                });
        } else {
            this.render(item);
        }
    }

    private readonly render = (item: QuickNavModel, viewdata?: any) => {
        this.remove();
        const componentFactory = this.factoryResolver.resolveComponentFactory(item.component);
        const componentRef = componentFactory.create(this.rootViewContainer.parentInjector);
        if (viewdata) {
            componentRef.instance.viewData = viewdata;
            componentRef.instance.cdref.detectChanges();
        }
        if (item.options.callBack) {
            componentRef.instance.callBack = item.options.callBack;
        }
        this.rootViewContainer.insert(componentRef.hostView);
    };

    remove(): void {
        if (!this.rootViewContainer) { return; }
        this.rootViewContainer.clear();
    }
}

export interface IQuicknavLoader {
    load(item: QuickNavModel): void;
    remove(): void;
}
