'use strict';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';

export class DesignElementItems {
    firmElementCaseRef: string;
    clientElementCaseRef: string;
    elementOfficialNo: string;
    registrationNo?: string;
    noOfViews?: number;
    elementDescription: string;
    renew?: boolean;
    stopRenewDate?: Date;
    images?: Array<DesignElementImage>;
    status?: rowStatus;
    error?: boolean;
    sequence?: number;
    rowKey: string;
}

export class DesignElementImage {
    key: number;
    description: string;
    imageStatus: string;
    image: any;
}