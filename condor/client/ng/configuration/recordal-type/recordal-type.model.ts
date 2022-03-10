'use strict';

import { IdService } from '@progress/kendo-angular-grid';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';

export class RecordalTypeItems {
    id: number;
    recordalType: string;
    requestEvent?: string;
    requestAction?: string;
    recordalEvent?: string;
    recordalAction?: string;
}

export class RecordalTypePermissions {
    canAdd: boolean;
    canEdit: boolean;
    canDelete: boolean;
}

export class RecordalTypeRequest {
    id: number;
    recordalType: string;
    requestEvent?: number;
    requestAction?: string;
    recordalEvent?: number;
    recordalAction?: string;
    status?: rowStatus;
    elements: Array<RecordalElementModel>;
}

export class RecordalElementModel {
    id: number;
    element: any;
    elementLabel: string;
    nameType?: any;
    attribute?: any;
    status?: rowStatus;

    constructor(id: number) {
        this.id = id;
    }
}

export enum EditAttribute {
    Mandatory = 'MAN',
    Display = 'DIS'
}