'use strict';

var router = require('express').Router();

router.post('/api/names/consolidate/:id', function(req, res) {
    res.json({
        result: {
            result: 'success',
            errors: []
        }
    });
});


module.exports = router;