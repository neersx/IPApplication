'use strict';

var router = require('express').Router();

router.get('/api/savedsearch/menu/:queryContextId', function (req, res) {
    var data = [{
        key: '2',
        icon: 'cpa-icon-lg',
        url: '#/case/searchresult?queryKey=2',
        text: 'US Patents',
        description: 'US Patents',
        items: null
    },
    {
        key: '1',
        icon: 'cpa-icon-users',
        url: '#/case/searchresult?queryKey=1',
        text: 'US Trademarks',
        description: 'US Trademarks',
        items: null
    },
    {
        key: '6',
        icon: 'cpa-icon-users',
        url: '#/case/searchresult?queryKey=6',
        text: 'Filing Cases',
        description: 'Filing Cases',
        items: null
    },
    {
        icon: null,
        url: null,
        key: 'Group1',
        text: 'Australia Cases',
        items: [{
            key: '3',
            icon: 'cpa-icon-users',
            url: '#/case/searchresult?queryKey=3',
            text: 'Trademarks',
            description: 'Trademarks for Australia',
            items: null
        },
        {
            key: '4',
            icon: 'cpa-icon-lg',
            url: '#/case/searchresult?queryKey=4',
            text: 'Designs',
            description: 'Designs for Australia',
            items: null
        }
        ]

    }
    ];
    res.json(
        data
    );
});

module.exports = router;