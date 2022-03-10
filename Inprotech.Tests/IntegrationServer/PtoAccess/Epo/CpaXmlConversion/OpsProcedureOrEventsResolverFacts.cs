using System;
using System.IO;
using System.Linq;
using System.Xml.Serialization;
using Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public class OpsProcedureOrEventsResolverFacts
    {
        static registerdocument Build(string xml)
        {
            var xmlSerializer = new XmlSerializer(typeof(registerdocument));
            var source = @"<reg:register-document xmlns:reg='http://www.epo.org/register'>" +
                         xml +
                         "</reg:register-document>";

            var stringReader = new StringReader(source);
            return (registerdocument) xmlSerializer.Deserialize(stringReader);
        }

        [Fact]
        public void ReturnsAdditionalInformationInComments()
        {
            const string testxml =
                @"
<reg:procedural-data>
    <reg:procedural-step id='RENEWAL_264520' procedure-step-phase='undefined'>
        <reg:procedural-step-code>RFEE</reg:procedural-step-code>
        <reg:procedural-step-text step-text-type='STEP_DESCRIPTION'>Renewal fee payment</reg:procedural-step-text>
        <reg:procedural-step-text step-text-type='YEAR'>03</reg:procedural-step-text>
        <reg:procedural-step-date step-date-type='DATE_OF_PAYMENT'>
            <reg:date>20130207</reg:date>
        </reg:procedural-step-date>
    </reg:procedural-step>
    <reg:procedural-step id='STEP_LOPR_58417' procedure-step-phase='examination'>
        <reg:procedural-step-code>LOPR</reg:procedural-step-code>
        <reg:procedural-step-text step-text-type='STEP_DESCRIPTION'>Loss of particular right</reg:procedural-step-text>
        <reg:procedural-step-text step-text-type='STEP_DESCRIPTION_NAME'>designated state RO</reg:procedural-step-text>
        <reg:procedural-step-text step-text-type='STEP_IDENTIFICATION'>DESTRO</reg:procedural-step-text>
        <reg:procedural-step-date step-date-type='DATE_OF_DISPATCH'>
            <reg:date>20120210</reg:date>
        </reg:procedural-step-date>
    </reg:procedural-step>
</reg:procedural-data>
";
            var registerdocument = Build(testxml);

            var r = new OpsProcedureOrEventsResolver().Resolve(registerdocument).ToArray();

            Assert.Contains(r, _ => _.Comments == "YEAR: 03");
            Assert.Contains(r, _ => _.Comments == "designated state RO;" + Environment.NewLine + "STEP IDENTIFICATION: DESTRO");
        }

        [Fact]
        public void ReturnsAnEntryForEachDateOrderByDateDescending()
        {
            const string testxml =
                @"
<reg:procedural-data>
    <reg:procedural-step id='STEP_RFPR_4821' procedure-step-phase='examination'>
        <reg:procedural-step-code>RFPR</reg:procedural-step-code>
        <reg:procedural-step-text step-text-type='STEP_DESCRIPTION'>Request for further processing</reg:procedural-step-text>
        <reg:procedural-step-text step-text-type='STEP_DESCRIPTION_NAME'>The application is deemed to be withdrawn due to non-payment of the search fee</reg:procedural-step-text>
        <reg:procedural-step-date step-date-type='DATE_OF_PAYMENT1'>
            <reg:date>20140411</reg:date>
        </reg:procedural-step-date>
        <reg:procedural-step-date step-date-type='DATE_OF_REQUEST'>
            <reg:date>20140411</reg:date>
        </reg:procedural-step-date>
        <reg:procedural-step-date step-date-type='RESULT_DATE'>
            <reg:date>20140428</reg:date>
        </reg:procedural-step-date>
        <reg:procedural-step-result>Request granted</reg:procedural-step-result>
    </reg:procedural-step>
</reg:procedural-data>
";

            var registerdocument = Build(testxml);

            var r = new OpsProcedureOrEventsResolver().Resolve(registerdocument).ToArray();

            Assert.Equal(3, r.Length);

            Assert.Equal("Request for further processing (date of request)", r.ElementAt(2).FormattedDescription);
            Assert.Equal("Request for further processing (date of payment1)", r.ElementAt(1).FormattedDescription);
            Assert.Equal("Request for further processing (result date)", r.ElementAt(0).FormattedDescription);

            Assert.Equal(new DateTime(2014, 4, 11), r.ElementAt(2).Date);
            Assert.Equal(new DateTime(2014, 4, 11), r.ElementAt(1).Date);
            Assert.Equal(new DateTime(2014, 4, 28), r.ElementAt(0).Date);

            Assert.True(r.All(_ => _.Comments == "The application is deemed to be withdrawn due to non-payment of the search fee"));
        }

        [Fact]
        public void ReturnsProceduralStepsAndDossierEvents()
        {
            const string testxml = @"
 <reg:events-data>
        <reg:dossier-event id='EVT_1579454' event-type='new'>
            <reg:event-date>
                <reg:date>20130614</reg:date>
            </reg:event-date>
            <reg:event-code>0009199EXPT</reg:event-code>
            <reg:event-text event-text-type='DESCRIPTION'>Change - extension states</reg:event-text>
            <reg:gazette-reference>
                <reg:gazette-num>2013/29</reg:gazette-num>
                <reg:date>20130717</reg:date>
            </reg:gazette-reference>
        </reg:dossier-event>
    </reg:events-data>
    <reg:procedural-data>
        <reg:procedural-step id='STEP_ABEX_295810' procedure-step-phase='examination'>
        <reg:procedural-step-code>ABEX</reg:procedural-step-code>
        <reg:procedural-step-text step-text-type='STEP_DESCRIPTION'>Amendments</reg:procedural-step-text>
        <reg:procedural-step-text step-text-type='Kind of amendment'>(claims and/or description)</reg:procedural-step-text>
        <reg:procedural-step-date step-date-type='DATE_OF_REQUEST'>
            <reg:date>20140722</reg:date>
        </reg:procedural-step-date>
    </reg:procedural-step>
</reg:procedural-data>
";

            var registerdocument = Build(testxml);

            var r = new OpsProcedureOrEventsResolver().Resolve(registerdocument).ToArray();

            Assert.Equal(2, r.Length);
        }
    }
}