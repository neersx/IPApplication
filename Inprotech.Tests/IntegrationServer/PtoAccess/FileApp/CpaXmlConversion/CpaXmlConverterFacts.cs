using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Autofac.Features.Indexed;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Builders;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion
{
    public class CpaXmlConverterFacts
    {
        readonly IFileAgents _fileAgents = Substitute.For<IFileAgents>();
        readonly IIndex<string, IFileCaseBuilder> _builders = Substitute.For<IIndex<string, IFileCaseBuilder>>();
        readonly IIndex<string, IApplicationDetailsConverter> _converters = Substitute.For<IIndex<string, IApplicationDetailsConverter>>();

        readonly XNamespace _cpaxmlNs = "http://www.cpasoftwaresolutions.com";

        readonly DataDownload _dataDownload = new DataDownload
        {
            Case = new EligibleCase(Fixture.Integer(), Fixture.String(), "FILE")
        };

        ICpaXmlConverter CreateSubject()
        {
            return new CpaXmlConverter(_fileAgents, _builders, _converters);
        }

        [Fact]
        public async Task ShouldConvertDraftFileCase()
        {
            var fileCase = new FileCase
            {
                Id = Fixture.String(),
                IpType = Fixture.String(),
                ApplicantName = Fixture.String(),
                CaseReference = Fixture.String(),
                Status = Fixture.String()
            };

            var inprotechFileCase = new FileCase
            {
                BibliographicalInformation = new Biblio
                {
                    Title = Fixture.String()
                }
            };

            _builders[fileCase.IpType].Build(fileCase.Id)
                                      .Returns(inprotechFileCase);

            var subject = CreateSubject();

            var cpaxml = XElement.Parse(await subject.Convert(_dataDownload, fileCase, null));
            var senderDetails = cpaxml.Descendants(_cpaxmlNs + "SenderDetails").Single();
            var caseDetails = cpaxml.Descendants(_cpaxmlNs + "CaseDetails").Single();

            Assert.Equal("FILE", (string) senderDetails.Element(_cpaxmlNs + "Sender"));
            Assert.Equal("Property", (string) caseDetails.Element(_cpaxmlNs + "CaseTypeCode"));

            Assert.Equal(fileCase.Id, (string) caseDetails.Element(_cpaxmlNs + "SenderCaseIdentifier"));

            Assert.Equal("Patent", (string) caseDetails.Element(_cpaxmlNs + "CasePropertyTypeCode"));

            Assert.Equal(_dataDownload.Case.CountryCode, (string) caseDetails.Element(_cpaxmlNs + "CaseCountryCode"));
            Assert.Equal(inprotechFileCase.BibliographicalInformation.Title, (string) caseDetails.Descendants(_cpaxmlNs + "DescriptionDetails").Single().Element(_cpaxmlNs + "DescriptionText"));

            Assert.Equal(fileCase.Status, caseDetails.GetCpaXmlEvent("STATUS", "EventText"));
        }

        [Fact]
        public async Task ShouldConvertInstructedFileCase()
        {
            var fileCase = new FileCase
            {
                Id = Fixture.String(),
                IpType = Fixture.String(),
                ApplicantName = Fixture.String(),
                CaseReference = Fixture.String(),
                Status = Fixture.String()
            };

            var inprotechFileCase = new FileCase
            {
                BibliographicalInformation = new Biblio
                {
                    Title = Fixture.String()
                }
            };

            var instruction = new Instruction
            {
                AcknowledgeDate = Fixture.Date().ToString("yyyy-MM-dd"),
                CompletedDate = Fixture.Date().ToString("yyyy-MM-dd"),
                FilingDate = Fixture.Date().ToString("yyyy-MM-dd"),
                FilingReceiptReceivedDate = Fixture.Date().ToString("yyyy-MM-dd"),
                SentToPtoDate = Fixture.Date().ToString("yyyy-MM-dd"),
                PassedToAgentDate = Fixture.Date().ToString("yyyy-MM-dd"),
                ReceivedDate = Fixture.Date().ToString("yyyy-MM-dd"),
                ApplicationNo = Fixture.String()
            };

            _builders[fileCase.IpType].Build(fileCase.Id)
                                      .Returns(inprotechFileCase);

            var subject = CreateSubject();

            var cpaxml = XElement.Parse(await subject.Convert(_dataDownload, fileCase, instruction));
            var senderDetails = cpaxml.Descendants(_cpaxmlNs + "SenderDetails").Single();
            var caseDetails = cpaxml.Descendants(_cpaxmlNs + "CaseDetails").Single();

            Assert.Equal("FILE", (string) senderDetails.Element(_cpaxmlNs + "Sender"));
            Assert.Equal("Property", (string) caseDetails.Element(_cpaxmlNs + "CaseTypeCode"));

            Assert.Equal(fileCase.Id, (string) caseDetails.Element(_cpaxmlNs + "SenderCaseIdentifier"));

            Assert.Equal("Patent", (string) caseDetails.Element(_cpaxmlNs + "CasePropertyTypeCode"));

            Assert.Equal(_dataDownload.Case.CountryCode, (string) caseDetails.Element(_cpaxmlNs + "CaseCountryCode"));
            Assert.Equal(inprotechFileCase.BibliographicalInformation.Title, (string) caseDetails.Descendants(_cpaxmlNs + "DescriptionDetails").Single().Element(_cpaxmlNs + "DescriptionText"));

            Assert.Equal(fileCase.Status, caseDetails.GetCpaXmlEvent("STATUS", "EventText"));

            Assert.Equal(instruction.CompletedDate, caseDetails.GetCpaXmlDate("COMPLETED"));
            Assert.Equal(instruction.AcknowledgeDate, caseDetails.GetCpaXmlDate("ACKNOWLEDGED"));
            Assert.Equal(instruction.FilingDate, caseDetails.GetCpaXmlDate("LOCAL FILING"));
            Assert.Equal(instruction.FilingReceiptReceivedDate, caseDetails.GetCpaXmlDate("FILING RECEIPT RECEIVED"));
            Assert.Equal(instruction.SentToPtoDate, caseDetails.GetCpaXmlDate("SENT TO PTO"));
            Assert.Equal(instruction.PassedToAgentDate, caseDetails.GetCpaXmlDate("SENT TO AGENT"));
            Assert.Equal(instruction.ReceivedDate, caseDetails.GetCpaXmlDate("RECEIVED BY AGENT"));
        }
    }
}