// Globally available resources for all applications.
angular.module('Inprotech.Localisation')
    .factory('globalResources', function () {
        'use strict';
        return {
            gErrorComms1: 'A communication error has occurred. Please try again. If the problem persists, contact an Administrator.',
            gErrorComms404: 'The requested resource could not be found. Please try again later. If the problem persists, contact an administrator.',
            gErrorComms500: 'There was a problem processing your request. Please contact an administrator.',
            gErrorCommsCorrelated500: 'There was a problem processing your request. Please contact administrator with the below token: ',
            gErrorComms403: 'You do not have sufficient privileges to perform this action.',
            gErrorCommsOther: 'An unexpected error has occured. Please try again. If the problem persists, contact an Administrator.',

            //Begin navBar
            nbReturnToInprotech: 'Return to Inprotech Home',
            nbLogout: 'Logout',
            //End navBar

            //Begin searchBar
            lblSearch: 'Search',
            lblCases: 'Cases',
            lblCaseSearchBuilder: 'Case Search Builder',
            //End searchBar

            //Begin menu
            menuPortal: 'Portal',
            menuInprotech: 'Inprotech',
            menuIntegration: 'Integration',
            menuCaseDataComparisonInbox: 'Case Data Comparison Inbox',
            menuSchedulePtoDataDownload: 'Schedule Data Download',
            menuConfigureUsptoCertificates: 'Configure USPTO Certificates',
            menuBulkCaseImport: 'Import Cases',
            menuMaintainPriorArt: 'Prior Art Search',
            menuFinancialReports: 'Financial Reports',
            menuBulkCaseImportStatus: 'Import Status',
            menuApplicationLinkSecurity: 'Application Link Security',
            menuSystemMaintenance: 'System Maintenance',
            menuSchemaMapping: 'Schema Mapping',
            menuWorkflowRules: 'Workflow Rules',
            menuPolicingDashboard: 'Policing Dashboard',
            //End menu

            //Begin autocomplete
            autocompleteEmptyResult: 'No results',
            //End autocomplete

            //Begin keyboard binding
            keyboardBindingNextItem: 'Select the next {0}',
            keyboardBindingPreviousItem: 'Select the previous {0}',
            keyboardBindingDefaultItemLiteral: 'item',
            keyboardBindingShowMenu: '\'?\' to show keyboard shortcuts',
            //End keyboard binding

            //Begin buttons
            gBtnYes: 'Yes',
            gBtnNo: 'No',
            gBtnClose: 'Close',
            //End buttons

            //Begin ngGrid
            lblGridNull: '[null]',
            lblGridSelectAll: 'Select All',
            ngAggregateLabel: 'items',
            ngGroupPanelDescription: 'Drag a column header here and drop it to group by that column.',
            ngSearchPlaceHolder: 'Search...',
            ngMenuText: 'Choose Columns:',
            ngShowingItemsLabel: 'Showing Items:',
            ngTotalItemsLabel: 'Total Items:',
            ngSelectedItemsLabel: 'Selected Items:',
            ngPageSizeLabel: 'Page Size:',
            ngPagerFirstTitle: 'First Page',
            ngPagerNextTitle: 'Next Page',
            ngPagerPrevTitle: 'Previous Page',
            ngPagerLastTitle: 'Last Page',
            //End ngGrid

            _: null
        };
    });
