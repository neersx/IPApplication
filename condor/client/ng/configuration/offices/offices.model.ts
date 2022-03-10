'use strict';

import { PicklistModal } from 'configuration/kot-text-types/kot-text-types.model';

export class OfficeItems {
    key: number;
    value: string;
    organisation: string;
    country: string;
    defaultLanguage: string;
}

export class OfficePermissions {
    canAdd: boolean;
    canEdit: boolean;
    canDelete: boolean;
}

export class OfficeData {
    id?: number;
    description?: string;
    organization?: PicklistModal;
    country?: PicklistModal;
    // region?: PicklistModal;
    language?: PicklistModal;
    // printer?: PicklistModal;
    userCode?: string;
    cpaCode?: string;
    irnCode?: string;
    itemNoPrefix?: string;
    itemNoFrom?: number;
    itemNoTo?: number;
    printerCode?: number;
    regionCode?: number;
}