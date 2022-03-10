using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using CPAXML;
using CPAXML.Extensions;
using Inprotech.Contracts;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.CpaXml;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.CpaXml
{
    public class CpaXmlConverterFacts
    {
        readonly XNamespace _cpaXmlNs = "http://www.cpasoftwaresolutions.com";
        readonly IBackgroundProcessLogger<CpaXmlConverter> _logger = Substitute.For<IBackgroundProcessLogger<CpaXmlConverter>>();

        CpaXmlConverter CreateSubject()
        {
            var createSenderDetails = Substitute.For<ICreateSenderDetails>();

            createSenderDetails.For(Arg.Any<string>(), Arg.Any<RequestType>())
                               .Returns(x => new SenderDetails((string) x[0])
                               {
                                   SenderRequestFixType = (RequestType) x[1]
                               });

            return new CpaXmlConverter(createSenderDetails, _logger);
        }

        static (string AppId, BiblioFile BiblioFile) BuildBiblioFile(Continuity continuity)
        {
            var appId = Fixture.Integer().ToString();

            var biblio = new BiblioFile
            {
                Summary = new BiblioSummary
                {
                    AppId = appId,
                    AppNumber = appId
                },
                Continuity = new List<Continuity>(new[] {continuity})
            };

            return (appId, biblio);
        }

        [Theory]
        [InlineData("This application is a National Stage Entry of", null)]
        [InlineData("is a National Stage Entry of", null)]
        [InlineData(" is a National Stage Entry OF  ", null)]
        [InlineData("  THIS APPLICATION IS A NATIONAL STAGE ENTRY OF ", null)]
        [InlineData("sdffslkjls;fg0", "NST")]
        public void ShouldDeriveNationalPhaseCaseCountryCodeAsPct(string description, string claimParentageType)
        {
            var fixture = BuildBiblioFile(new Continuity
            {
                ApplicationNumber = "PCT/US2020/034245",
                Description = description,
                ClaimParentageType = claimParentageType
            });

            var r = CreateSubject().Convert(fixture.BiblioFile, fixture.AppId);

            var cpaxml = XElement.Parse(r);

            var caseDetails = cpaxml.Descendants(_cpaXmlNs + "CaseDetails").Single();

            var associatedCaseDetail = caseDetails.ParseAssociatedCaseDetails().Single();

            Assert.Equal(claimParentageType?.Trim() ?? description.Trim(), associatedCaseDetail.AssociatedCaseComment);
            Assert.Equal("PCT", associatedCaseDetail.AssociatedCaseCountryCode);
        }

        [Theory]
        [InlineData("Claims Priority from Provisional Application", null)]
        [InlineData("  CLAIMS PRIORITY FROM PROVISIONAL APPLICATION ", null)]
        [InlineData("This application Claims Priority from Provisional Application", null)]
        [InlineData("  THIS APPLICATION CLAIMS PRIORITY FROM PROVISIONAL APPLICATION", null)]
        [InlineData("dlajflkdfsl", "PRO")]
        public void ShouldDeriveProvisionalApplicationCountryCodeAsTheStates(string description, string claimParentageType)
        {
            var fixture = BuildBiblioFile(new Continuity
            {
                ApplicationNumber = "32,324/234",
                Description = description,
                ClaimParentageType = claimParentageType
            });

            var r = CreateSubject().Convert(fixture.BiblioFile, fixture.AppId);

            var cpaXml = XElement.Parse(r);

            var caseDetails = cpaXml.Descendants(_cpaXmlNs + "CaseDetails").Single();

            var associatedCaseDetail = caseDetails.ParseAssociatedCaseDetails().Single();

            Assert.Equal(claimParentageType?.Trim() ?? description.Trim(), associatedCaseDetail.AssociatedCaseComment);
            Assert.Equal("US", associatedCaseDetail.AssociatedCaseCountryCode);
        }

        [Theory]
        [InlineData("This application is a Continuation of", null, "PCT/CC2021/0123425", "PCT")]
        [InlineData("is a continuation of", null, "9,907,650", "US")]
        [InlineData(" THIS APPLICATION IS A CONTINUATION OF ", null, "9,907,650", "US")]
        [InlineData(" IS A CONTINUATION OF ", null, "PCT/CC2021/0123425", "PCT")]
        [InlineData(" IS A CONTINUATION OF ", null, "PCT/CC2021/0123425", "PCT")]
        [InlineData("fjdasljf", "CON", "PCT/CC2021/0123425", "PCT")]
        public void ShouldDeriveContinuationCaseCountryCodeFromItsNumbers(string description, string claimParentageType, string parentNumber, string expectedCountryCode)
        {
            var fixture = BuildBiblioFile(new Continuity
            {
                ApplicationNumber = parentNumber,
                PatentNumber = Fixture.Integer().ToString(),
                Description = description,
                ClaimParentageType = claimParentageType
            });

            var r = CreateSubject().Convert(fixture.BiblioFile, fixture.AppId);

            var cpaXml = XElement.Parse(r);

            var caseDetails = cpaXml.Descendants(_cpaXmlNs + "CaseDetails").Single();

            var associatedCaseDetail = caseDetails.ParseAssociatedCaseDetails().Single();

            Assert.Equal(claimParentageType?.Trim() ?? description.Trim(), associatedCaseDetail.AssociatedCaseComment);
            Assert.Equal(expectedCountryCode, associatedCaseDetail.AssociatedCaseCountryCode);
        }
        
        [Theory]
        [InlineData(" THIS APPLICATION IS A CONTINUATION IN PART OF ", null, "9,907,650", "US")]
        [InlineData(" IS A CONTINUATION-IN-PART OF ", null, "PCT/CC2021/0123425", "PCT")]
        [InlineData("djfajlkfafg", "UNKNOWN-VALUE-YET", "PCT/CC2021/0123425", "PCT")]
        public void ShouldDeriveContinuationInPartCaseCountryCodeFromItsNumbers(string description, string claimParentageType, string parentNumber, string expectedCountryCode)
        {
            var fixture = BuildBiblioFile(new Continuity
            {
                ApplicationNumber = parentNumber,
                PatentNumber = Fixture.Integer().ToString(),
                Description = description,
                ClaimParentageType = claimParentageType
            });

            var r = CreateSubject().Convert(fixture.BiblioFile, fixture.AppId);

            var cpaXml = XElement.Parse(r);

            var caseDetails = cpaXml.Descendants(_cpaXmlNs + "CaseDetails").Single();

            var associatedCaseDetail = caseDetails.ParseAssociatedCaseDetails().Single();

            Assert.Equal(claimParentageType?.Trim() ?? description.Trim(), associatedCaseDetail.AssociatedCaseComment);
            Assert.Equal(expectedCountryCode, associatedCaseDetail.AssociatedCaseCountryCode);
        }

        [Fact]
        public void ShouldParseInventorNameCorrectly()
        {
            var country = Fixture.String();
            var state = Fixture.String();
            var city = Fixture.String();
            var firstName = Fixture.String();
            var lastName = Fixture.String().ToUpper();
            var inventor = $"{firstName} {lastName}, {city}, {state} ({country})";
            var fixture = BuildBiblioFile(new Continuity
            {
                ApplicationNumber = Fixture.String(),
                PatentNumber = Fixture.Integer().ToString(),
                Description = Fixture.String()
            });

            fixture.BiblioFile.Summary.Inventor = inventor;

            var r = CreateSubject().Convert(fixture.BiblioFile, fixture.AppId);

            var cpaXml = XElement.Parse(r);

            var caseDetails = cpaXml.Descendants(_cpaXmlNs + "CaseDetails").Single();
            var inventorDetails = caseDetails.Descendants(_cpaXmlNs + "NameDetails").Single();
            Assert.Equal("Inventor", (string) inventorDetails.Element(_cpaXmlNs +"NameTypeCode"));

            var addressBook = inventorDetails.Descendants(_cpaXmlNs +"AddressBook").Single();
            Assert.Equal(country, addressBook.Descendants(_cpaXmlNs + "AddressCountryCode").Single().Value);
            Assert.Equal(state, addressBook.Descendants(_cpaXmlNs + "AddressState").Single().Value);
            Assert.Equal(city, addressBook.Descendants(_cpaXmlNs + "AddressCity").Single().Value);
            Assert.Equal($"{lastName}, {firstName}", inventorDetails.Descendants(_cpaXmlNs + "FreeFormatName").First().Value);
        }

        [Theory]
        [InlineData("This application is a Division of", null, "PCT/CC2021/0123425", "PCT")]
        [InlineData("is a Division of", null, "9,907,650", "US")]
        [InlineData("akdfjlafjgks", "DIV", "9,907,650", "US")]
        public void ShouldDeriveDivisionalCaseCountryCodeFromItsNumbers(string description, string claimParentageType, string parentNumber, string expectedCountryCode)
        {
            var fixture = BuildBiblioFile(new Continuity
            {
                ApplicationNumber = parentNumber,
                PatentNumber = Fixture.Integer().ToString(),
                Description = description,
                ClaimParentageType = claimParentageType
            });

            var r = CreateSubject().Convert(fixture.BiblioFile, fixture.AppId);

            var cpaXml = XElement.Parse(r);

            var caseDetails = cpaXml.Descendants(_cpaXmlNs + "CaseDetails").Single();

            var associatedCaseDetail = caseDetails.ParseAssociatedCaseDetails().Single();

            Assert.Equal(claimParentageType?.Trim() ?? description.Trim(), associatedCaseDetail.AssociatedCaseComment);
            Assert.Equal(expectedCountryCode, associatedCaseDetail.AssociatedCaseCountryCode);
        }

        [Theory]
        [InlineData("PCT/CC2021/0123425", "PCT")]
        [InlineData("9,907,650", "US")]
        public void ShouldDeriveCountryCodeFromApplicationNumber(string applicationNumber, string expectedCountryCode)
        {
            var biblio = new BiblioFile
            {
                Summary = new BiblioSummary
                {
                    AppId = applicationNumber,
                    AppNumber = applicationNumber
                }
            };

            var r = CreateSubject().Convert(biblio, applicationNumber);

            var cpaXml = XElement.Parse(r);

            var caseDetails = cpaXml.Descendants(_cpaXmlNs + "CaseDetails").Single();

            Assert.Equal(expectedCountryCode, (string) caseDetails.Element(_cpaXmlNs + "CaseCountryCode"));
        }

        [Theory]
        [InlineData("This application is a National Stage Entry of", null)]
        [InlineData("is a National Stage Entry of", null)]
        [InlineData(" is a National Stage Entry OF  ", null)]
        [InlineData("  THIS APPLICATION IS A NATIONAL STAGE ENTRY OF ", null)]
        [InlineData("akldsjdfadsf", "NST")]
        public void ShouldPullPctApplicationDateIfItIsNationalPhaseFiling(string nationalPhaseEntryStringToMatch, string claimParentageTypeForNationalPhase)
        {
            var pctFilingDate = Fixture.Date();
            var localFilingDate = pctFilingDate.AddMonths(12);

            var applicationNumber = Fixture.String("PCT");
            var biblio = new BiblioFile
            {
                Summary = new BiblioSummary
                {
                    AppId = applicationNumber,
                    AppNumber = applicationNumber,
                    FilingDate371 = localFilingDate.Iso8601OrNull()
                },
                Continuity = new List<Continuity>(new []
                                                  {
                            new Continuity
                            {
                                ApplicationNumber = Fixture.String("PCT"),
                                Description = nationalPhaseEntryStringToMatch,
                                ClaimParentageType = claimParentageTypeForNationalPhase,
                                FilingDate371 = pctFilingDate.Iso8601OrNull()
                            }
                                                  })
            };

            var r = CreateSubject().Convert(biblio, applicationNumber);

            var cpaXml = XElement.Parse(r);

            var caseDetails = cpaXml.Descendants(_cpaXmlNs + "CaseDetails").Single();

            Assert.Equal(localFilingDate.Iso8601OrNull(), caseDetails.GetCpaXmlDate("Local Filing"));
            Assert.Equal(pctFilingDate.Iso8601OrNull(), caseDetails.GetCpaXmlDate("Application"));
        }

        [Fact]
        public void ShouldPull371FilingDateIfItIsUsFiling()
        {
            var usFilingDate = Fixture.Date();

            var applicationNumber = Fixture.Integer().ToString();
            var biblio = new BiblioFile
            {
                Summary = new BiblioSummary
                {
                    AppId = applicationNumber,
                    AppNumber = applicationNumber,
                    FilingDate371 = usFilingDate.Iso8601OrNull()
                }
            };

            var r = CreateSubject().Convert(biblio, applicationNumber);

            var cpaXml = XElement.Parse(r);

            var caseDetails = cpaXml.Descendants(_cpaXmlNs + "CaseDetails").Single();

            Assert.Null(caseDetails.GetCpaXmlDate("Local Filing"));
            Assert.Equal(usFilingDate.Iso8601OrNull(), caseDetails.GetCpaXmlDate("Application"));
        }

        [Fact]
        public void ShouldConvertBiblioFileToCpaXml()
        {
            var json = Tools.ReadFromEmbededResource(GetType().Namespace + ".Biblio1.json");

            var biblio = JsonConvert.DeserializeObject<BiblioFile>(json);

            var cpaXml = XElement.Parse(CreateSubject().Convert(biblio, "12331223"));

            var caseDetails = cpaXml.Descendants(_cpaXmlNs + "CaseDetails").Single();

            var associatedCaseDetails = caseDetails.ParseAssociatedCaseDetails().ToArray();

            var parentContinuity = biblio.Continuity.Where(_ => !string.IsNullOrWhiteSpace(_.ApplicationNumber)).ToArray();

            Assert.Equal(biblio.Summary.AttorneyDocketNumber, (string) caseDetails.Element(_cpaXmlNs + "SenderCaseReference"));

            Assert.Equal("Patent", (string) caseDetails.Element(_cpaXmlNs + "CasePropertyTypeCode"));

            Assert.Equal(biblio.Summary.AppNumber, caseDetails.GetCpaXmlNumber("Application"));

            Assert.Equal(biblio.Summary.FilingDate371, caseDetails.GetCpaXmlDate("Application"));

            Assert.Equal(biblio.Summary.PublicationNumber, caseDetails.GetCpaXmlNumber("Publication"));

            Assert.Equal(biblio.Summary.PublicationDate, caseDetails.GetCpaXmlDate("Publication"));

            Assert.Equal(biblio.Summary.PatentNumber, caseDetails.GetCpaXmlNumber("Registration/Grant"));

            Assert.Equal(biblio.Summary.IssueDate, caseDetails.GetCpaXmlDate("Registration/Grant"));

            Assert.Equal(biblio.Summary.StatusDate, caseDetails.GetCpaXmlDate("Status"));

            Assert.Equal(parentContinuity.Length, associatedCaseDetails.Count(_ => _.AssociatedCaseRelationshipCode == "Parent Continuity"));

            for (var i = 0; i < parentContinuity.Length; i++)
            {
                Assert.Equal(parentContinuity[i].Description, associatedCaseDetails[i].AssociatedCaseStatus);

                Assert.Equal(parentContinuity[i].ApplicationNumber, associatedCaseDetails[i].AssociatedCaseIdentifierNumberDetails.GetCpaXmlNumber("Application"));

                Assert.Equal(parentContinuity[i].FilingDate371, associatedCaseDetails[i].AssociatedCaseEventDetails.GetCpaXmlDate("Application"));

                Assert.Equal(parentContinuity[i].Description, associatedCaseDetails[i].AssociatedCaseComment);
            }
        }
    }
}