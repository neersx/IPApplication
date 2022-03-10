'use strict';

var router = require('express').Router();


module.exports = router;

router.get('/api/ptoaccess/uspto/privatepair/sponsorships', function(req, res) {
    var response = {
        canScheduleDataDownload: true,
        envInvalid: false,
        clientId: '39f5c1a7394d141540fa237ca6f45e7a',
        sponsorships: [{
            id: 1,
            name: 'Firmwide Sponsorship',
            customerNumbers: '12345, 23478',
            email: 'attorney@firm.com',
            schedules: 'Initial Load',
            serviceId: '9837e736a3c234ba0f6ba33995cfab8f'
        }, {
            id: 2,
            name: 'John\'s Certificate',
            email: 'attorney2@firm.com',
            customerNumbers: '45689, 89101',
            status: 'error',
            statusDate: '2018-12-11',
            errorMessage: '401: Password is not valid',
            serviceId: '7d954f2198674aa5bdaa4ec8d101ac47'
        }, {
            id: 3,
            name: 'Patents Department',
            customerNumbers: '12345, 23478, 45689, 89101',
            email: 'anotherSposnor@firm.com',
            schedules: 'Daily Status Checks, Daily Document Downloads',
            serviceId: '82e96c99633e461db8de6b922332c227'
        }, {
            id: 4,
            name: 'Adam\'s Certificate',
            email: 'att@firm.com',
            customerNumbers: '345, 98767',
            status: 'error',
            statusDate: new Date(),
            errorMessage: '408: No Sponsor found',
            serviceId: '936f7c4519cb4eadb576eb9ddeb4f60c'
        }]
    };

    return res.json(response);
});


router.delete('/api/ptoaccess/uspto/privatepair/sponsorships/:SponsorshipId', function(req, res) {
    res.json({
        result: 'success'
    });
})

router.post('/api/ptoaccess/uspto/privatepair/sponsorships', function(req, res) {
    res.json({
        result: {
            viewData: {
                isSuccess: true
            }
        }
    });
});