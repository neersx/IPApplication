'use strict';

var router = require('express').Router();
var fs = require('fs');
var path = require('path');

router.get('/api/configuration/nametypes/search', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/viewdata.json'));
    res.type('json');
    fileStream.pipe(res);
});

router.get('/api/configuration/nametypes/:id', function(req, res) {
    var entity = JSON.parse(fs.readFileSync(path.join(__dirname, '/viewdataMaintenance.json')));
    res.json(entity);
});

router.post('/api/configuration/nametypes/delete', function(req, res) {
    res.json({
       message: 'deleted'
    });
});

router.post('/api/configuration/nametypes', function(req, res) {
    res.json({
        result: {
            result: 'success',
            updatedId: parseInt(req.params[0])
        }
    });
});

router.put('/api/configuration/nametypes/*', function(req, res) {
    res.json({
        result: {
            result: 'success',
            updatedId: parseInt(req.params[0])
        }
    });
});

module.exports = router;
