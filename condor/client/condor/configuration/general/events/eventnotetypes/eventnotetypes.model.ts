namespace inprotech.configuration.general.events.eventnotetypes {
    'use strict';

export class EventNoteTypeModel {
    id: number | null;
    description: string;
    sharingAllowed: boolean | null;
    isExternal: boolean | null;
    state: string;
    saved: boolean;
}

export interface IEventNoteTypeModalOptions extends IModalOptions {
        entity?: EventNoteTypeModel;
    }
}