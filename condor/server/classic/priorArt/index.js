'use strict';

var router = require('express').Router();

function buildViewData() {
    return {
        viewData: {
            sourceId: 1,
            sourceType: 'Document Source',
            description: 'Document Description.This could be long.'
        }
    };
}

function buildData() {
    var data = [{
        source: 'ExistingPriorArtFinder',
        matches: [{
            sourceDocumentId: null,
            isCited: false,
            id: '3',
            reference: '1780036',
            citation: 'Citation Reported',
            title: 'Booklet finishing apparatus, post-treatment apparatus, and image forming system',
            name: null,
            kind: 'A3',
            abstract: 'A booklet finishing apparatus',
            applicationDate: null,
            publishedDate: null,
            isComplete: false,
            type: 'ExistingPriorArtMatch'
        }],
        errors: false,
        message: null
    }, {
        source: 'CaseEvidenceFinder',
        matches: [],
        errors: false,
        message: null
    }, {
        source: 'DiscoverEvidenceFinder',
        matches: [{
            id: '0',
            reference: 'EP-1780036-A3',
            citation: null,
            title: 'Booklet finishing apparatus, post-treatment apparatus, and image forming system',
            name: 'Awano; Hiroaki; c/o Fuji Xerox Co.; Ltd.',
            kind: 'A3',
            abstract: 'A booklet finishing apparatus.',
            applicationDate: '2006-06-14T00:00:00Z',
            publishedDate: '2014-01-08T00:00:00Z',
            isComplete: true,
            type: 'Match',
            imported: true
        }, {
            id: '0',
            reference: 'EP-1780036-A2',
            citation: null,
            title: 'Booklet finishing apparatus, post-treatment apparatus, and image forming system',
            name: 'Awano; Hiroaki; c/o Fuji Xerox Co.; Ltd.',
            kind: 'A2',
            abstract: 'A booklet finishing apparatus.',
            applicationDate: '2006-06-14',
            publishedDate: '2007-05-02',
            isComplete: true,
            type: 'Match'
        }],
        errors: false,
        message: null
    }];
    return data;
}

router.get('/api/priorart/priorartsearchview', function(req, res) {
    res.json(buildViewData());
});

router.get('/api/priorart/priorarteditview', function(req, res) {
    res.json({});
});

router.get('/api/priorart/evidencesearch', function(req, res) {
    res.json(buildData());
});


module.exports = router;