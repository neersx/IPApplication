'use strict';

var router = require('express').Router();

router.get('/api/casesupport/casetype/typeaheadsearchall', function(req, res) {
    res.json({
        caseTypes: [{
            'code': 'A',
            'value': 'Properties'
        }, {
            'code': 'D',
            'value': 'Designs'
        }]
    });
});

module.exports = router;
