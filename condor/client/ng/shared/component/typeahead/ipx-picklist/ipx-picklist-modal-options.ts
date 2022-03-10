export class IpxModalOptions {
    constructor(public multipick = false,
        public searchValue = '',
        public selectedItems: Array<any> = [],
        public picklistCanMaintain = false,
        public columnMenu = false,
        public extendQuery: any,
        public extendedParams: any,
        public externalScope: any,
        public qualifiers: any,
        public editUriState = false,
        public canAddAnother = false,
        public previewable = false,
        public entity = '',
        public isAddAnother = false,
        public canNavigate = false,
        public picklistNewSearch = false,
        public extendedSearchFields = false
        ) {

    }
}
