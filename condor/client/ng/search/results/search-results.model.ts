
export interface SearchResultColumn {
  id: string;
  title: string;
  format: string;
  decimalPlaces: number;
  currencyCodeColumnName: string;
  isHyperlink: boolean;
  filterable: boolean;
  fieldId: string;
  columnItemId?: string;
  linkType: string;
  linkArgs: Array<string>;
  isColumnFreezed: boolean;
  width: number;
  groupBySortOrder?: number;
  groupBySortDirection?: string;
}

export interface SearchResult {
  totalRows: number;
  columns: Array<SearchResultColumn>;
  rows: Array<{ [id: string]: any; }>;
}