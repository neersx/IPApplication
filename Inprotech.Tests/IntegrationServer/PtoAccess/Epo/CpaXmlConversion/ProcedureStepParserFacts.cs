using System;
using System.IO;
using System.Linq;
using System.Xml.Serialization;
using Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public class ProcedureStepParserFacts
    {
        static proceduralstep Build(string xml)
        {
            var xmlSerializer = new XmlSerializer(typeof(proceduraldata));
            var source = @"<reg:procedural-data xmlns:reg='http://www.epo.org/register'>" +
                         xml +
                         "</reg:procedural-data>";

            var stringReader = new StringReader(source);
            var pd = (proceduraldata) xmlSerializer.Deserialize(stringReader);
            return pd.proceduralstep.First();
        }

        [Fact]
        public void ExtractsAmendments()
        {
            const string testxml =
                @"
<reg:procedural-step id='STEP_ABEX_295810' procedure-step-phase='examination'>
    <reg:procedural-step-code>ABEX</reg:procedural-step-code>
    <reg:procedural-step-text step-text-type='STEP_DESCRIPTION'>Amendments</reg:procedural-step-text>
    <reg:procedural-step-text step-text-type='Kind of amendment'>(claims and/or description)</reg:procedural-step-text>
    <reg:procedural-step-date step-date-type='DATE_OF_REQUEST'>
        <reg:date>20140722</reg:date>
    </reg:procedural-step-date>
</reg:procedural-step>
";
            var r = new ProcedureStepParser().Parse(Build(testxml));

            Assert.Equal("ABEX", r.Code);
            Assert.False(r.DoesNotContainAnyDates);
            Assert.Equal("Amendments", r.Description["STEP_DESCRIPTION"]);
            Assert.Equal("(claims and/or description)", r.Text["Kind of amendment"]);
            Assert.Equal(new DateTime(2014, 07, 22), r.Date["DATE_OF_REQUEST"]);
        }

        [Fact]
        public void ExtractsExamination()
        {
            const string testxml =
                @"
<reg:procedural-step id='STEP_EXRE_27408' procedure-step-phase='examination'>
    <reg:procedural-step-code>EXRE</reg:procedural-step-code>
    <reg:procedural-step-text step-text-type='STEP_DESCRIPTION'>Communication from the examining division</reg:procedural-step-text>
    <reg:procedural-step-date step-date-type='DATE_OF_DISPATCH'>
        <reg:date>20081128</reg:date>
    </reg:procedural-step-date>
    <reg:procedural-step-date step-date-type='DATE_OF_REPLY'>
        <reg:date>20090608</reg:date>
    </reg:procedural-step-date>
    <reg:time-limit time-limit-unit='months'>06</reg:time-limit>
</reg:procedural-step>
";
            var r = new ProcedureStepParser().Parse(Build(testxml));

            Assert.Equal("EXRE", r.Code);
            Assert.False(r.DoesNotContainAnyDates);
            Assert.Equal("Communication from the examining division", r.Description["STEP_DESCRIPTION"]);

            Assert.Equal(new DateTime(2008, 11, 28), r.Date["DATE_OF_DISPATCH"]);
            Assert.Equal(new DateTime(2009, 06, 08), r.Date["DATE_OF_REPLY"]);
            Assert.Equal("06 months", r.Timelimit);
        }

        [Fact]
        public void ExtractsProceduralLanguage()
        {
            const string testxml =
                @"
<reg:procedural-step id='STEP_PROL_53237' procedure-step-phase='examination'>
    <reg:procedural-step-code>PROL</reg:procedural-step-code>
    <reg:procedural-step-text step-text-type='STEP_DESCRIPTION'>Language of the procedure</reg:procedural-step-text>
    <reg:procedural-step-text step-text-type='procedure language'>de</reg:procedural-step-text>
</reg:procedural-step>
";

            var r = new ProcedureStepParser().Parse(Build(testxml));

            Assert.Equal("PROL", r.Code);
            Assert.True(r.DoesNotContainAnyDates);
            Assert.Equal("Language of the procedure", r.Description["STEP_DESCRIPTION"]);
            Assert.Equal("de", r.Text["procedure language"]);
        }

        [Fact]
        public void ExtractsRequestForFurtherProcessing()
        {
            const string testxml =
                @"
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
";
            var r = new ProcedureStepParser().Parse(Build(testxml));

            Assert.Equal("RFPR", r.Code);
            Assert.False(r.DoesNotContainAnyDates);
            Assert.Equal("Request for further processing", r.Description["STEP_DESCRIPTION"]);
            Assert.Equal("The application is deemed to be withdrawn due to non-payment of the search fee",
                         r.Text["STEP_DESCRIPTION_NAME"]);
            Assert.Equal(new DateTime(2014, 04, 11), r.Date["DATE_OF_PAYMENT1"]);
            Assert.Equal(new DateTime(2014, 04, 11), r.Date["DATE_OF_REQUEST"]);
            Assert.Equal(new DateTime(2014, 04, 28), r.Date["RESULT_DATE"]);
        }

        [Fact]
        public void OrganisesProcedureStepDataForCpaxmlGeneration()
        {
            const string testxml =
                @"
<reg:procedural-step id='RENEWAL_264519' procedure-step-phase='undefined'>
    <reg:procedural-step-code>RFEE</reg:procedural-step-code>
    <reg:procedural-step-text step-text-type='STEP_DESCRIPTION'>Renewal fee payment</reg:procedural-step-text>
    <reg:procedural-step-text step-text-type='YEAR'>02</reg:procedural-step-text>
    <reg:procedural-step-date step-date-type='DATE_OF_PAYMENT'>
        <reg:date>20120207</reg:date>
    </reg:procedural-step-date>
</reg:procedural-step>";

            var r = new ProcedureStepParser().Parse(Build(testxml));
            Assert.Equal("Renewal fee payment", r.Description["STEP_DESCRIPTION"]);
            Assert.Equal("02", r.Text["YEAR"]);
            Assert.Equal(new DateTime(2012, 2, 7), r.Date["DATE_OF_PAYMENT"]);
            Assert.Equal("RFEE", r.Code);
        }
    }
}