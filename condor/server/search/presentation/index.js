
'use strict';

var router = require('express').Router();
router.get('/api/search/presentation/available/:queryContextKey', function(req, res) {
    res.json([]);
});

router.get('/api/search/presentation/selected/:queryContextKey/:queryKey', function(req, res) {
    res.json([]);
});

module.exports = router;
