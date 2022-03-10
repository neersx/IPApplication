'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../../utils');

var buildMappingViewResponse = function(id) {
    return utils.readJson(path.join(__dirname, '/mapping-result.json'), function(data) {
        data.id = id;
        return data;
    });
};

var buildDependencyUploadResponse = function(missingDependencies) {
    return {
        status: 'SchemaFileCreated',
        schemaFile: {
            id: 1,
            name: 'OHIM Trademark application V2',
            lastModified: '2015/03/03'
        },
        missingDependencies: missingDependencies
    };
};

var buildFileNameExistsResponse = function(contentsMatch) {
    return {
        status: 'FileAlreadyExists',
        uploadedFileId: 'gfsdgsdfsdf',
        existingFileId: 'gtsdfsdfsdt',
        mappingId: 1,
        contentsMatch: contentsMatch,
        missingDependencies: ['ISOLanguageCodeType-V2004.xsd', 'WIPOST3CodeType-V2012.xsd']
    };
};

var buildSchemaPackageFilesResponse = function() {
    return {
        status: 'SchemaPackageDetails',
        package: {
            id: 3,
            name: 'ABCD',
            isValid: false,
            updatedOn: '2017-10-17T19:49:18.12',
            createdOn: '2017-10-17T19:49:18.12'
        },
        error: 'filesRequired',
        files: [{
            id: 7,
            name: 'ISOLanguageCodeType-V2002.xsd',
            lastModified: '2017-10-17T19:49:18.12'
        }, {
            id: 8,
            name: 'WIPOST3CodeType-V2011.xsd',
            lastModified: '2017-10-17T19:49:18.12'
        }, {
            id: 9,
            name: 'ISOLanguageCodeType-V2002_1.xsd',
            lastModified: '2017-10-17T19:49:18.12'
        }, {
            id: 10,
            name: 'WIPOST3CodeType-V2011_2.xsd',
            lastModified: '2017-10-17T19:49:18.12'
        }],
        missingDependencies: ['ISOLanguageCodeType-V2004.xsd', 'WIPOST3CodeType-V2012.xsd']
    };
};

var buildMappingsResponse = function() {
    return [{
        id: 1,
        name: 'OHIM Trademark application',
        schemaPackageId: 1,
        schemaPackageName: 'TM-eFiling-reduced.xsd',
        isValid: false,
        lastModified: '2017-10-17T19:49:18.12',
        rootNode: {
            fileName: 'abcd.xsd',
            qualifiedName: 'transaction'
        }
    }, {
        id: 2,
        name: 'OHIM Patent application',
        schemaPackageId: 1,
        schemaPackageName: 'TM-eFiling-reduced.xsd',
        isValid: true,
        lastModified: '2017-10-17T19:49:18.12',
        rootNode: {
            fileName: 'xyz.xsd',
            qualifiedName: 'root'
        }
    }, {
        id: 3,
        name: 'IPA TM Application',
        schemaPackageId: 3,
        schemaPackageName: 'IPB_B2B_BatchRequestV1.5',
        isValid: true,
        lastModified: '2017-10-17T19:49:18.12',
        rootNode: {
            fileName: 'efg.dtd',
            qualifiedName: 'transaction'
        }
    }]
};

var buildSchemasResponse = function() {
    return [{
        id: 1,
        name: 'TM-eFiling-reduced.xsd',
        updatedOn: '2017-10-17T19:49:18.12',
        createdOn: '2017-10-17T19:49:18.12',
        isValid: true
    }, {
        id: 2,
        name: 'TM-eFiling-reducedV2.xsd',
        updatedOn: '2017-10-17T19:49:18.12',
        createdOn: '2017-10-17T19:49:18.12',
        isValid: true

    }, {
        id: 3,
        name: 'IPB_B2B_BatchRequestV1.5.xsd',
        updatedOn: '2017-10-17T19:49:18.12',
        createdOn: '2017-10-17T19:49:18.12',
        isValid: false
    }, {
        id: 4,
        name: 'IPB_B2B_BatchRequestV1.5_1.xsd',
        updatedOn: '2017-10-17T19:49:18.12',
        createdOn: '2017-10-17T19:49:18.12',
        isValid: false
    }, {
        id: 5,
        name: 'IPB_B2B_BatchRequestV1.5_2.xsd',
        updatedOn: '2017-10-17T19:49:18.12',
        createdOn: '2017-10-17T19:49:18.12',
        isValid: true
    }, {
        id: 6,
        name: 'IPB_B2B_BatchRequestV1.5_3.xsd',
        updatedOn: '2017-10-17T19:49:18.12',
        createdOn: '2017-10-17T19:49:18.12',
        isValid: true
    }];
};

var xml = '<?xml version="1.0" encoding="utf-16" standalone="yes"?>\n' +
    '<case>\n' +
    '<irn>1234/B</irn>\n' +
    '<title>RONDON &amp; shoe device</title>\n' +
    '<family>No Family</family>\n' +
    '<owner>Aspargus Holdings Pty Limited</owner>\n' +
    '<instructor>Asparagus Farming Equipment Pty Ltd</instructor>\n' +
    '<event caseId="-486">Convention Period - Foreign Filings</event>\n' +
    '<event caseId="-486">Reopen Lodgement Action</event>\n' +
    '<event caseId="-486">TM Status Inquiry - awaiting action</event>\n' +
    '<event caseId="-486">Foreign filing convention deadline</event>\n' +
    '<event caseId="-486">Expected date for 1st Official Action</event>\n' +
    '<event caseId="-486">Open Forms Action</event>\n' +
    '<event caseId="-486">Open Formalities Law Update Service Action</event>\n' +
    '<event caseId="-486">Open Lodgement Action</event>\n' +
    '<event caseId="-486">Instructions Received Date for new case</event>\n' +
    '<event caseId="-486">Date of Entry</event>\n' +
    '<event caseId="-486">Open Examination Action</event>\n' +
    '<event caseId="-486">Application Filing Date</event>\n' +
    '<event caseId="-486">Earliest Priority Date</event>\n' +
    '<event caseId="-486">Date of Last Change</event>\n' +
    '</case>';

var buildSuccessfulXmlGenerationResponse = function() {
    return xml;
};

var buildFailedXmlGenerationResponse = function() {
    return {
        xml: xml,
        error: 'validation error'
    };
};

router.get('/api/schemamappings/mappings', function(req, res) {
    res.json(buildMappingsResponse());
});

router.delete('/api/schemamappings/*', function(req, res) {
    res.json({});
});

router.get('/api/schemapackage/list', function(req, res) {
    res.json(buildSchemasResponse());
});

router.get('/api/schemapackage/*/details', function(req, res) {
    res.json(buildSchemaPackageFilesResponse());
});

router.post('/api/schemapackage/*', function(request, res) {
    if (_.indexOf(['file-exists.xsd'], request.body.fileName) !== -1) {
        return res.json(buildFileNameExistsResponse(true));
    } else if (_.indexOf(['overwrite-exists.xsd'], request.body.fileName) !== -1) {
        return res.json(buildFileNameExistsResponse(false));
    } else if (_.indexOf(['dependency.xsd'], request.body.fileName) !== -1) {
        return res.json(buildDependencyUploadResponse([]));
    } else if (_.indexOf(['missing-dependencies.xsd'], request.body.fileName) !== -1) {
        return res.json(buildDependencyUploadResponse(['ISOLanguageCodeType-V2004.xsd', 'WIPOST3CodeType-V2012.xsd']));
    } else {
        res.json({
            name: request.body.fileName
        });
    }
});

router.delete('/api/schemapackage/*', function(req, res) {
    res.json({});
});

router.put('/api/schemapackage/*', function(req, res) {
    res.json({});
});

router.get('/api/schemamappings/*/xmlView/*', function(req, res) {
    var regex = /api\/schemamappings\/(\d+)\/xmlView/i;
    var mappingId = regex.exec(path)[1];

    if (mappingId === '3') {
        return res.json(buildFailedXmlGenerationResponse());
    }
    return res.json(buildSuccessfulXmlGenerationResponse());
});

router.get('/api/schemaMappings/mappingView/*', function(req, res) {
    return res.json(buildMappingViewResponse(1));
});

router.get('api/schemapackage/*/roots',
    function(req, res) {
        return res.json({
            status: 'RootNodes',
            nodes: [{
                name: 'root1',
                isDtdFile: true,
                fileName: 'ABCD'
            }]
        });
    });

module.exports = router;