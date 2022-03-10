module inprotech.portfolio.cases {
    export class EventNote {
        noteText: String;
        notetype: String;
        noteTypeDescription: String;
        constructor(_noteText, _notetype, _noteTypeDescription) {
            this.noteText = _noteText;
            this.notetype = _notetype;
            this.noteTypeDescription = _noteTypeDescription;
        }
    }

    export class EventNoteDetailsController {
        static $inject = ['$scope', 'kendoGridBuilder', '$timeout'];
        notes;
        categories;
        public vm: EventNoteDetailsController;
        public gridOptions: any;
        public viewData: any;
        public eventTextItems;
        public hasNoteTypes: boolean;
        public filteredCategories: any;

        constructor(private $scope: any, private kendoGridBuilder: any, private $timeout) {
            this.vm = this;
        }

        $onInit() {
            this.vm = this;
            if (this.categories && this.categories.length > 0) {
                this.hasNoteTypes = true;
            }

            this.filteredCategories = this.notes ? this.getCategories(this.notes.map(n => n.noteType), this.categories) : null;
            this.eventTextItems = this.getEventitems(this.notes, this.filteredCategories);
            this.gridOptions = this.buildGridOptions();
        }

        public buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'eventNoteDetails',
                autoBind: true,
                pageable: false,
                reorderable: false,
                sortable: false,
                navigatable: true,
                selectOnNavigate: true,
                autoGenerateRowTemplate: true,
                read: (queryParams) => {
                    if (queryParams && queryParams.filters && queryParams.filters.length > 0) {
                        let filters = queryParams.filters[0].value.split(',');
                        return _.filter(this.eventTextItems, (t) => {
                            return (queryParams.filters[0].operator === 'in' && queryParams.filters[0].field === 'notetype') ? filters.indexOf(String((t as any).notetype)) >= 0
                                : false;
                        })
                    }

                    return this.eventTextItems;
                },
                readFilterMetadata: (columns) => {
                    return this.$timeout(() => {
                        return this.filteredCategories;
                    }, 0);
                },
                filterOptions: {
                    keepFiltersAfterRead: true,
                    sendExplicitValues: true
                },
                columns: this.getColumns()
            });
        }

        public encodeLinkData = (data) => {
            return encodeURIComponent(JSON.stringify(data));
        };

        private getColumns() {
            let initialNoteTypeFilters = _.filter(this.filteredCategories, (fc) => { return (fc as any).isDefault }).map(c => String(c['code']));
            let columns = [{
                title: 'caseview.actions.events.eventDetailNote',
                field: 'notes',
                template: '<div ng-if="::dataItem.noteText" class="display-wrap"><ip-text-area content="::dataItem.noteText"></ip-text-area></div>'

            }, {
                title: 'caseview.actions.events.eventDetailType',
                field: 'notetype',
                filterable: true,
                defaultFilters: initialNoteTypeFilters,
                width: '160px',
                template: '<span>{{::dataItem.noteTypeDescription}}</span>'
            }];

            if (!this.hasNoteTypes) {
                columns.splice(1, 1);
            }

            return columns;
        }

        private getEventitems = (values: String, filteredCategories: any) => {
            let items = [];
            angular.forEach(values, (value: any) => {
                let noteTypeText = _.filter(filteredCategories, (c) => {
                    return ((c as any).code) === (value as any).noteType;
                }) as any;

                items = items.concat((value as any).eventText.split(/(?=\n---)/g).map(r => new EventNote(r.replace(/\n---/g, '---'), (value as any).noteType, noteTypeText.length === 0 ? null : noteTypeText[0].description)));
            });
            return items;
        }

        private getCategories = (noteTypes, categories) => {
            let items = [];
            items = _.filter(categories, (c) => {
                return (c as any).code === '' || (c as any).isDefault || noteTypes.indexOf((c as any).code) > -1;
            })

            return items;
        }
    }

    angular.module('inprotech.portfolio.cases')
        .component('ipEventNoteDetails', {
            controllerAs: 'vm',
            bindings: {
                notes: '<',
                categories: '<'
            },
            templateUrl: 'condor/portfolio/cases/directives/event-note-details.html',
            controller: EventNoteDetailsController
        });
}