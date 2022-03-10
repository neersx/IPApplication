'use strict';

var router = require('express').Router();
var fs = require('fs');
var path = require('path');


router.get('/api/configuration/names/locality/viewdata', function(req, res) {
    res.json({});
});

router.get('/api/configuration/names/locality/search', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/searchResults.json'));
    res.type('json');
    fileStream.pipe(res);
});

router.get('/api/configuration/names/locality/:id', function(req, res) {
    var entity = JSON.parse(fs.readFileSync(path.join(__dirname, '/dataMaintenance.json')));
    res.json(entity);
});

router.post('/api/configuration/names/locality/delete', function(req, res) {
    res.json({
       message: 'deleted'
    });
});

router.post('/api/configuration/names/locality', function(req, res) {
    res.json({
        result: {
            result: 'success',
            updatedId: parseInt(req.params[0])
        }
    });
});

router.put('/api/configuration/names/locality/*', function(req, res) {
    res.json({
        result: {
            result: 'success',
            updatedId: parseInt(req.params[0])
        }
    });
});

module.exports = router;