angular.module('Inprotech.FinancialReports')
    .run(['localise',
        function (localise) {
            'use strict';
            localise.initialize({

                //Begin navBar
                nbReturnToInprotech: 'Return to Inprotech Home',
                nbLogout: 'Logout',
                //End navBar

                _: null
            });
        }
    ]);
