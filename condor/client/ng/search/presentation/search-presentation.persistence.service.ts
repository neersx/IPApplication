import { Injectable } from '@angular/core';
import { ISearchPresentationData, SearchPresentationData } from './search-presentation.model';

@Injectable()
export class SearchPresentationPersistenceService {
    private _searchPresentationData: ISearchPresentationData = {};

    setSearchPresentationData = (value: SearchPresentationData, key = '1') => {
        this._searchPresentationData = this._searchPresentationData ? this._searchPresentationData : {};
        this._searchPresentationData[key] = value ? { ...value } : null;
    };

    getSearchPresentationData = (key = '1'): SearchPresentationData => {
        return this._searchPresentationData ? this._searchPresentationData[key] : null;
    };

    clear = () => {
        this._searchPresentationData = null;
    };
}