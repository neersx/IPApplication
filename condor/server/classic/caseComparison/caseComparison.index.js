'use strict';

function buildDiscrepancyData() {
    return {
        viewData: {
            updateable: true,
            'case': {
                caseId: -123,
                ref: {
                    inprotech: '001234/0449-US',
                    uspto: '1001.1502105',
                    different: true
                },
                title: {
                    inprotech: 'VASCULAR DEVICE HAVING ONE OR MORE ARTICULATION REGIONS AND METHODS OF USE',
                    uspto: 'Vascular device having one or more articulation regions and methods of use',
                    different: true
                },
                status: {
                    inprotech: 'Registered',
                    uspto: '150 - Patented Case'
                },
                statusDate: {
                    inprotech: '2003-01-01T00:00:00',
                    uspto: '2003-02-20T00:00:00',
                    different: true,
                    updateable: true
                },
                localClasses: {
                    uspto: '606/200',
                    different: true,
                    updateable: true
                }
            },
            caseImage: {
                caseImageIds: ['sample-trademark.png', 'sample-trademark.png'],
                downloadedThumbnailId: 'sample-trademark.png',
                downloadedImageId: 'sample-trademark-large.png'
            },
            caseNames: [{
                nameType: 'Examiner',
                name: {
                    uspto: 'JACKSON, GARY',
                    different: true,
                    updateable: true
                }
            }, {
                nameType: 'Inventor',
                name: {
                    inprotech: 'Hopkins, Leo N.United States of America',
                    uspto: 'HOPKINS LEO'
                },
                address: {
                    ourValue: '46 York St\nSydney',
                    uspto: '46 YORK ST\nSYDNEY'
                }
            }, {
                nameType: 'Inventor',
                name: {
                    uspto: 'KHOSRAVI, FARHAD',
                    different: true,
                    updateable: false
                },
                address: {
                    theirValue: '46 York St\nSydney',
                    different: true,
                    updateable: false
                }
            }],
            officialNumbers: [{
                id: 321,
                numberType: 'Registration/Grant',
                number: {
                    inprotech: '6129739',
                    uspto: '111-0808',
                    different: true,
                    updateable: true
                },
                'event': 'Register On',
                eventDate: {
                    inprotech: '2010-11-15T00:00:00',
                    uspto: '2010-11-15T00:00:00'
                }
            }, {
                id: 654,
                numberType: 'Application',
                number: {
                    inprotech: '09470857',
                    uspto: '09/470,857'
                },
                'event': 'Application Filing Date',
                eventDate: {
                    inprotech: '2010-11-15T00:00:00',
                    uspto: '2002-07-19T00:00:00',
                    different: true,
                    updateable: true
                }
            }],
            events: [{
                eventType: 'Change of Address filed',
                cycle: 2,
                eventDate: {
                    uspto: '2002-06-03T00:00:00',
                    theirDescription: 'amended by request from client',
                    different: true,
                    updateable: true
                }
            }, {
                eventType: 'Mail Notice of Allowance',
                cycle: 3,
                eventDate: {
                    uspto: '2002-02-26T00:00:00',
                    different: true,
                    updateable: true
                }
            }, {
                eventType: 'Information Disclosure Statement(IDS) Field',
                cycle: 1,
                eventDate: {
                    inprotech: '2001-11-15T00:00:00',
                    uspto: '2001-11-15T00:00:00'
                }
            }],
            goodsServices: [{
                textKey: 1,
                'class': {
                    ourValue: null,
                    theirValue: '009',
                    different: true,
                    updateable: true
                },
                firstUsedDate: {
                    format: 'P',
                    ourValue: null,
                    theirValue: null,
                    different: false,
                    updateable: false
                },
                firstUsedDateInCommerce: {
                    format: 'P',
                    ourValue: null,
                    theirValue: null,
                    different: false,
                    updateable: false
                },
                text: {
                    ourValue: 'Mobile telephones; hello world; portable media players; portable computers; smart phones and tablet computers; rechargeable batteries; battery chargers; tablet computers; 3D eye glasses; computers; software for mobile phone device management, security and parental controls, downloadable computer game software for children, and software for music and educational activities and games for children',
                    theirValue: 'Mobile telephones; digital cameras; portable media players; portable computers; wireless headsets for mobile phones, smart phones and tablet computers; rechargeable batteries; battery chargers; leather cases for mobile phones, smart phones and tablet computers; flip covers for mobile phones, smart phones and tablet computers; tablet computers; television receivers; audio electronic components, namely surround sound systems; digital set-top boxes; DVD players; Light emitting diode displays; monitors, namely, television monitors, liquid crystal display (LCD) monitors, computer monitors; 3D eye glasses; computers; printers for computers; semiconductors; software for mobile phone device management, security and parental controls, downloadable computer game software for children, and software for music and educational activities and games for children',
                    different: true,
                    updateable: true
                }
            }, {
                textKey: null,
                'class': {
                    ourValue: null,
                    theirValue: '045',
                    different: true,
                    updateable: true
                },
                firstUsedDate: {
                    format: 'MonthYear',
                    ourValue: null,
                    theirValue: '2013-09-09T00:00:00',
                    different: true,
                    updateable: true
                },
                firstUsedDateInCommerce: {
                    format: 'P',
                    ourValue: null,
                    theirValue: '2013-09-09T00:00:00',
                    different: true,
                    updateable: true
                },
                text: {
                    ourValue: null,
                    theirValue: 'Assisting localities and local entities in organizing and establishing groups of practicing and retired physicians, nurses, and other health professionals to act in a coordinated manner in times of local emergencies; Background investigation and research services; Background investigation services; Case management services, namely, coordination of legal, social and psychological services for elderly persons; Chaperoning; Charitable services, namely, providing emotional support services for the elderly by means of providing home assessments, medical equipment, technology, construction services, instruction and educational services, transportation, elevators, lifts, and the like, private nursing, home care and other personal care services; Conducting day programs for the elderly and adults with physical and mental challenges, namely, coffee clubs in the nature of social conversations while having coffee; Conducting on-line personal lifestyle performance assessments based on principles of emotional happiness by means of the users\' inputted preferences and social network; Counseling in the field of personal development, namely, self-improvement, self-fulfillment, and interpersonal communication; Home safety consulting in the field of enabling the elderly to remain in their homes; In-home support services to senior persons, namely, geriatric care management services in the nature of the coordination of necessary services and personal care for older individuals; Life quality assessment for individuals with developmental disabilities and their families; Medical alarm monitoring services; Monitoring of security systems; Monitoring of home systems for security purposes; Non-medical in-home personal care services for assisting with daily living activities of the elderly; Personal care assistance of activities of daily living, such as bathing, grooming and personal mobility for mentally or physically challenged people; Personal concierge services for others comprising making requested personal arrangements and reservations and providing customer-specific information to meet individual needs; Personal concierge services for others comprising making requested personal arrangements and reservations, running errands and providing customer specific information to meet individual needs, all rendered in business establishments, office buildings, hotels, residential complexes and homes; Personal reminder services in the area of upcoming important dates and events; Providing case management services, namely, coordinating legal, medical, physical, social, personal care and psychological services for the elderly; Providing case management services, namely, coordinating legal, physical, social and psychological services for disabled persons; Providing case management services, namely, coordinating legal, physical, social and psychological services for the elderly; Providing non-medical in-home personal services for individuals including checking home condition, supplies and individual well-being, scheduling appointments, running errands, making safety checks, and providing on-line information related to these personal services; Providing non-medical personal assistant services for others in the nature of planning, organizing, coordinating, arranging and assisting individuals to perform daily tasks; Providing personal support services for caregivers, partners, wives and husbands of the chronically ill and/or disabled, namely, companionship and emotional support; Running errands for others',
                    different: true,
                    updateable: true
                }
            }, {
                textKey: null,
                'class': {
                    ourValue: null,
                    theirValue: '046',
                    different: true,
                    updateable: true
                },
                firstUsedDate: {
                    format: 'Year',
                    ourValue: null,
                    theirValue: '2013-12-31T00:00:00',
                    different: true,
                    updateable: true
                },
                firstUsedDateInCommerce: {
                    format: 'Year',
                    ourValue: '2013-06-01T00:00:00',
                    theirValue: '2013-12-31T00:00:00',
                    different: true,
                    updateable: true
                },
                text: {
                    ourValue: null,
                    theirValue: 'Class 046 is best class',
                    different: true,
                    updateable: true
                }
            }],
            parentRelatedCases: [{
                description: {
                    ourValue: 'Conventional Claim From',
                    theirValue: 'Priority',
                    different: true
                },
                countryCode: {
                    ourValue: 'US',
                    theirValue: 'US'
                },
                officialNumber: {
                    ourValue: '11223344',
                    theirValue: 'AA1122/3344'
                },
                relatedCaseRef: '1234/A',
                priorityDate: {
                    ourValue: '2013-06-01T00:00:00',
                    theirValue: '2013-12-31T00:00:00',
                    different: true
                },
                parentStatus: {
                    ourValue: 'Inprotech Status',
                    theirValue: 'Imported Status',
                    different: true
                }
            }]
        }
    };
}

function buildDiscrepancyDataRejectable() {
    return {
        viewData: {
            updateable: true,
            rejectable: true,
            'case': {
                caseId: -123,
                ref: {
                    ourValue: '001234/0449-US',
                    theirValue: '1001.1502105',
                    different: true
                },
                title: {
                    ourValue: 'VASCULAR DEVICE HAVING ONE OR MORE ARTICULATION REGIONS AND METHODS OF USE',
                    theirValue: 'Vascular device having one or more articulation regions and methods of use',
                    different: true
                }
            },
            caseNames: [{
                nameType: 'Inventor',
                name: {
                    ourValue: 'Hopkins, Leo N.United States of America',
                    theirValue: 'HOPKINS LEO'
                },
                address: {
                    ourValue: '46 York St\nSydney',
                    theirValue: '46 YORK ST\nSYDNEY'
                }
            }, {
                nameType: 'Inventor',
                name: {
                    ourValue: 'KHOSRAVI, FARHAD',
                    different: true,
                    updateable: false
                },
                address: {
                    theirValue: '46 York St\nSydney',
                    different: true,
                    updateable: false
                }
            }],
            officialNumbers: [{
                id: 321,
                numberType: 'Registration/Grant',
                number: {
                    ourValue: '6129739',
                    theirValue: '111-0808',
                    different: true,
                    updateable: true
                },
                'event': 'Register On',
                eventDate: {
                    ourValue: '2010-11-15T00:00:00',
                    theirValue: '2010-11-15T00:00:00'
                }
            }, {
                id: 654,
                numberType: 'Application',
                number: {
                    ourValue: '09470857',
                    theirValue: '09/470,857'
                },
                'event': 'Application Filing Date',
                eventDate: {
                    ourValue: '2010-11-15T00:00:00',
                    theirValue: '2002-07-19T00:00:00',
                    different: true,
                    updateable: true
                }
            }]
        }
    };
}

function buildDataWithDuplicates() {
    return {
        viewData: {
            updateable: true,
            hasDuplicates: true,
            'case': {
                caseId: -123,
                ref: {
                    ourValue: '004444/0449-US',
                    theirValue: '4001.1502105',
                    different: true
                },
                title: {
                    ourValue: 'Example Case With Duplicates',
                    theirValue: 'Example Case With Duplicatessssssssssssssss',
                    different: true
                }
            },
            caseNames: [{
                nameType: 'Inventor',
                name: {
                    ourValue: 'Hopkins, Leo N.United States of America',
                    theirValue: 'HOPKINS LEO'
                },
                address: {
                    ourValue: '46 York St\nSydney',
                    theirValue: '46 YORK ST\nSYDNEY'
                }
            }],
            officialNumbers: [{
                id: 321,
                numberType: 'Registration/Grant',
                number: {
                    ourValue: '6129739',
                    theirValue: '111-0808',
                    different: true,
                    updateable: true
                },
                'event': 'Register On',
                eventDate: {
                    ourValue: '2010-11-15T00:00:00',
                    theirValue: '2010-11-15T00:00:00'
                }
            }]
        }
    };
}

function buildAccurateData() {
    return {
        success: true,
        viewData: {
            'case': {
                caseId: -123,
                ref: {
                    inprotech: '1001.1502105',
                    uspto: '1001.1502105'
                },
                title: {
                    inprotech: 'Vascular device having one or more articulation regions and methods of use',
                    uspto: 'Vascular device having one or more articulation regions and methods of use'
                },
                status: {
                    inprotech: 'Registered',
                    uspto: '150 - Patented Case'
                },
                statusDate: {
                    inprotech: '2003-02-20T00:00:00',
                    uspto: '2003-02-20T00:00:00'
                },
                localClasses: {
                    inprotech: '606/200',
                    uspto: '606/200'
                }
            },
            caseNames: [{
                nameType: 'Examiner',
                name: {
                    inprotech: 'JACKSON, GARY',
                    uspto: 'JACKSON, GARY'
                }
            }, {
                nameType: 'Inventor',
                name: {
                    inprotech: 'Hopkins, Leo N.United States of America',
                    uspto: 'HOPKINS LEO'
                }
            }, {
                nameType: 'Inventor',
                name: {
                    inprotech: 'KHOSRAVI, FARHAD',
                    uspto: 'KHOSRAVI, FARHAD'
                }
            }],
            officialNumbers: [{
                id: 321,
                numberType: 'Registration/Grant',
                number: {
                    inprotech: '111-0808',
                    uspto: '111-0808'
                },
                'event': 'Register On',
                eventDate: {
                    inprotech: '2010-11-15T00:00:00',
                    uspto: '2010-11-15T00:00:00'
                }
            }, {
                id: 654,
                numberType: 'Application',
                number: {
                    inprotech: '09470857',
                    uspto: '09/470,857'
                },
                'event': 'Application Filing Date',
                eventDate: {
                    inprotech: '2010-11-15T00:00:00',
                    uspto: '2002-11-15T00:00:00'
                }
            }],
            events: [{
                eventType: 'Change of Address filed',
                cycle: 2,
                eventDate: {
                    inprotech: '2002-06-03T00:00:00',
                    uspto: '2002-06-03T00:00:00'
                }
            }, {
                eventType: 'Mail Notice of Allowance',
                cycle: 3,
                eventDate: {
                    inprotech: '2002-02-26T00:00:00',
                    uspto: '2002-02-26T00:00:00'
                }
            }, {
                eventType: 'Information Disclosure Statement(IDS) Field',
                cycle: 1,
                eventDate: {
                    inprotech: '2001-11-15T00:00:00',
                    uspto: '2001-11-15T00:00:00'
                }
            }],
            goodsServices: [{
                textType: 'G',
                textNo: 1,
                'class': {
                    ourValue: '009',
                    theirValue: '009',
                    different: false,
                    updateable: false
                },
                firstUsedDate: {
                    format: 'P',
                    ourValue: null,
                    theirValue: null,
                    different: false,
                    updateable: false
                },
                firstUsedDateInCommerce: {
                    format: 'P',
                    ourValue: null,
                    theirValue: null,
                    different: false,
                    updateable: false
                },
                text: {
                    ourValue: 'Mobile telephones; digital cameras; portable media players; portable computers; wireless headsets for mobile phones, smart phones and tablet computers; rechargeable batteries; battery chargers; leather cases for mobile phones, smart phones and tablet computers; flip covers for mobile phones, smart phones and tablet computers; tablet computers; television receivers; audio electronic components, namely surround sound systems; digital set-top boxes; DVD players; Light emitting diode displays; monitors, namely, television monitors, liquid crystal display (LCD) monitors, computer monitors; 3D eye glasses; computers; printers for computers; semiconductors; software for mobile phone device management, security and parental controls, downloadable computer game software for children, and software for music and educational activities and games for children',
                    theirValue: 'Mobile telephones; digital cameras; portable media players; portable computers; wireless headsets for mobile phones, smart phones and tablet computers; rechargeable batteries; battery chargers; leather cases for mobile phones, smart phones and tablet computers; flip covers for mobile phones, smart phones and tablet computers; tablet computers; television receivers; audio electronic components, namely surround sound systems; digital set-top boxes; DVD players; Light emitting diode displays; monitors, namely, television monitors, liquid crystal display (LCD) monitors, computer monitors; 3D eye glasses; computers; printers for computers; semiconductors; software for mobile phone device management, security and parental controls, downloadable computer game software for children, and software for music and educational activities and games for children',
                    different: false,
                    updateable: false
                }
            }, {
                textType: 'G',
                textNo: 2,
                'class': {
                    ourValue: '045',
                    theirValue: '045',
                    different: false,
                    updateable: false
                },
                firstUsedDate: {
                    format: 'MonthYear',
                    ourValue: '2013-09-09T00:00:00',
                    theirValue: '2013-09-09T00:00:00',
                    different: false,
                    updateable: false
                },
                firstUsedDateInCommerce: {
                    format: 'P',
                    ourValue: '2013-09-09T00:00:00',
                    theirValue: '2013-09-09T00:00:00',
                    different: false,
                    updateable: false
                },
                text: {
                    ourValue: 'Assisting localities and local entities in organizing and establishing groups of practicing and retired physicians, nurses, and other health professionals to act in a coordinated manner in times of local emergencies; Background investigation and research services; Background investigation services; Case management services, namely, coordination of legal, social and psychological services for elderly persons; Chaperoning; Charitable services, namely, providing emotional support services for the elderly by means of providing home assessments, medical equipment, technology, construction services, instruction and educational services, transportation, elevators, lifts, and the like, private nursing, home care and other personal care services; Conducting day programs for the elderly and adults with physical and mental challenges, namely, coffee clubs in the nature of social conversations while having coffee; Conducting on-line personal lifestyle performance assessments based on principles of emotional happiness by means of the users\' inputted preferences and social network; Counseling in the field of personal development, namely, self-improvement, self-fulfillment, and interpersonal communication; Home safety consulting in the field of enabling the elderly to remain in their homes; In-home support services to senior persons, namely, geriatric care management services in the nature of the coordination of necessary services and personal care for older individuals; Life quality assessment for individuals with developmental disabilities and their families; Medical alarm monitoring services; Monitoring of security systems; Monitoring of home systems for security purposes; Non-medical in-home personal care services for assisting with daily living activities of the elderly; Personal care assistance of activities of daily living, such as bathing, grooming and personal mobility for mentally or physically challenged people; Personal concierge services for others comprising making requested personal arrangements and reservations and providing customer-specific information to meet individual needs; Personal concierge services for others comprising making requested personal arrangements and reservations, running errands and providing customer specific information to meet individual needs, all rendered in business establishments, office buildings, hotels, residential complexes and homes; Personal reminder services in the area of upcoming important dates and events; Providing case management services, namely, coordinating legal, medical, physical, social, personal care and psychological services for the elderly; Providing case management services, namely, coordinating legal, physical, social and psychological services for disabled persons; Providing case management services, namely, coordinating legal, physical, social and psychological services for the elderly; Providing non-medical in-home personal services for individuals including checking home condition, supplies and individual well-being, scheduling appointments, running errands, making safety checks, and providing on-line information related to these personal services; Providing non-medical personal assistant services for others in the nature of planning, organizing, coordinating, arranging and assisting individuals to perform daily tasks; Providing personal support services for caregivers, partners, wives and husbands of the chronically ill and/or disabled, namely, companionship and emotional support; Running errands for others',
                    theirValue: 'Assisting localities and local entities in organizing and establishing groups of practicing and retired physicians, nurses, and other health professionals to act in a coordinated manner in times of local emergencies; Background investigation and research services; Background investigation services; Case management services, namely, coordination of legal, social and psychological services for elderly persons; Chaperoning; Charitable services, namely, providing emotional support services for the elderly by means of providing home assessments, medical equipment, technology, construction services, instruction and educational services, transportation, elevators, lifts, and the like, private nursing, home care and other personal care services; Conducting day programs for the elderly and adults with physical and mental challenges, namely, coffee clubs in the nature of social conversations while having coffee; Conducting on-line personal lifestyle performance assessments based on principles of emotional happiness by means of the users\' inputted preferences and social network; Counseling in the field of personal development, namely, self-improvement, self-fulfillment, and interpersonal communication; Home safety consulting in the field of enabling the elderly to remain in their homes; In-home support services to senior persons, namely, geriatric care management services in the nature of the coordination of necessary services and personal care for older individuals; Life quality assessment for individuals with developmental disabilities and their families; Medical alarm monitoring services; Monitoring of security systems; Monitoring of home systems for security purposes; Non-medical in-home personal care services for assisting with daily living activities of the elderly; Personal care assistance of activities of daily living, such as bathing, grooming and personal mobility for mentally or physically challenged people; Personal concierge services for others comprising making requested personal arrangements and reservations and providing customer-specific information to meet individual needs; Personal concierge services for others comprising making requested personal arrangements and reservations, running errands and providing customer specific information to meet individual needs, all rendered in business establishments, office buildings, hotels, residential complexes and homes; Personal reminder services in the area of upcoming important dates and events; Providing case management services, namely, coordinating legal, medical, physical, social, personal care and psychological services for the elderly; Providing case management services, namely, coordinating legal, physical, social and psychological services for disabled persons; Providing case management services, namely, coordinating legal, physical, social and psychological services for the elderly; Providing non-medical in-home personal services for individuals including checking home condition, supplies and individual well-being, scheduling appointments, running errands, making safety checks, and providing on-line information related to these personal services; Providing non-medical personal assistant services for others in the nature of planning, organizing, coordinating, arranging and assisting individuals to perform daily tasks; Providing personal support services for caregivers, partners, wives and husbands of the chronically ill and/or disabled, namely, companionship and emotional support; Running errands for others',
                    different: false,
                    updateable: false
                }
            }]
        }
    };


}

function buildErrorData() {
    return {
        success: true,
        viewData: {
            'errors': [{
                type: 'Mapping',
                key: 'NAMETYPE',
                message: ['A', 'B', 'C']
            }, {
                type: 'Mapping',
                key: 'COUNTRY',
                message: ['AYYY', 'BEEE', 'CEEE']
            }]
        }
    };
}

function buildDocumentData() {
    return {
        result: [{
            category: 'Search / examination',
            code: null,
            description: 'Confirmation of withdrawal of application/closure of proceedings',
            errors: null,
            id: 415,
            imported: false,
            mailRoomDate: '2010-02-09T00:00:00',
            pageCount: 1,
            status: 'Downloaded'
        }]
    };
}


'use strict';

var router = require('express').Router();

router.get('/api\/casecomparison\/n\/666*/*', function(req, res) {
    return res.json(buildErrorData());
});

router.get('/api\/casecomparison\/n\/777*/*', function(req, res) {
    return res.json(buildDiscrepancyDataRejectable());
});

router.get('/api\/casecomparison\/n\/888*/*', function(req, res) {
    return res.json(buildDataWithDuplicates());
});

router.get('/api\/casecomparison\/n*/*', function(req, res) {
    return res.json(buildDiscrepancyData());
});

router.get('/api/casecomparison/saveChanges/*', function(req, res) {
    return res.json(buildAccurateData());
});

router.get('/api/casecomparison/*/documents*/*', function(req, res) {
    return res.json(buildDocumentData());
});

module.exports = router;