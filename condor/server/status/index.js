'use strict';

var router = require('express').Router();
var fs = require('fs');
var path = require('path');
var _ = require('underscore');

router.get('/api/configuration/status', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/searchresults.json'));
    res.type('json');
    fileStream.pipe(res);
});

router.get('/api/configuration/status/supportdata', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/viewdata.json'));
    res.type('json');
    fileStream.pipe(res);
});

router.get('/api/configuration/status/:id', function(req, res) {
    var all = JSON.parse(fs.readFileSync(path.join(__dirname, '/searchresults.json')));
    var entity = _.find(all, function(item) {
        return item.id === parseInt(req.params.id);
    });
    res.json(entity);
});

router.post('/api/configuration/status', function(req, res) {
    res.json({
        result: 'success',
        updatedId: -200
    });
});

router.put('/api/configuration/status/*', function(req, res) {
    res.json({
        result: 'success',
        updatedId: parseInt(req.params[0])
    });
});

router.delete('/api/configuration/status/*', function(req, res) {
    res.json({
        result: 'success'
    });
});

module.exports = router;
