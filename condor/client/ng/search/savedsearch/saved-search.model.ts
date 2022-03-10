import { SelectedColumn } from 'search/presentation/search-presentation.model';

interface IPicklistModel {
    key?: Number;
    value?: String;
}

export class SaveSearchEntity {
    id?: Number;
    queryContext?: Number;
    searchName?: String;
    isPublic?: Boolean;
    description?: String;
    groupKey?: Number;
    searchFilter: any;
    updatePresentation: Boolean;
    selectedColumns: Array<SelectedColumn>;
}

export enum SaveOperationType {
    Add,
    EditDetails,
    SaveAs,
    Update
}

export class SaveSearchData {
    searchName?: String;
    description?: String;
    includeInSearchMenu?: IPicklistModel;
    public?: Boolean;
}