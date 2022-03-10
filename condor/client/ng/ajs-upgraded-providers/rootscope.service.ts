import { Inject, Injectable } from '@angular/core';
import { IRootScopeService } from 'angular';

@Injectable()
export class RootScopeService {
    rootScope: any;
    isHosted: boolean;
    constructor(@Inject('$rootScope') private readonly _rootScope: IRootScopeService) {
        this.rootScope = this._rootScope;
        this.isHosted = (this._rootScope as any).isHosted;
    }
}