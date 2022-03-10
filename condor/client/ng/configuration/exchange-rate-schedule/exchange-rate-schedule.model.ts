
'use strict';

export class ExchangeRateSchedulePermissions {
    canAdd: boolean;
    canEdit: boolean;
    canDelete: boolean;
}

export class ExchangeRateScheduleItems {
    id: number;
    code: string;
    description: string;
}

export class ExchangeRateScheduleRequest {
    id?: number;
    code: string;
    description: string;
}