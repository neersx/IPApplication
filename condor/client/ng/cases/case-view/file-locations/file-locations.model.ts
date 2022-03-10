'use strict';

export class FileLocationsItems {
    id: number;
    fileLocationId: number;
    fileLocation?: any;
    whenMoved: Date;
    filePartId?: number;
    filePart?: any;
    issuedBy?: any;
    issuedById?: number;
    bayNo?: string;
    barCode?: string;
    caseIrn: string;
    status?: string;
    rowKey?: number;
}