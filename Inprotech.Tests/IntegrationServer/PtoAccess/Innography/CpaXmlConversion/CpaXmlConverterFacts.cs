using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using CPAXML;
using CPAXML.Extensions;
using Inprotech.IntegrationServer.PtoAccess.Innography.CpaXmlConversion;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.CpaXmlConversion
{
    public class CpaXmlConverterFacts
    {
        readonly CpaXmlConverter _subject = new CpaXmlConverter();
        readonly XNamespace _cpaxmlNs = "http://www.cpasoftwaresolutions.com";
        const string SuccessMessage = "VERIFICATION_SUCCESS";
        const string FailureMessage = "VERIFICATION_FAILURE";

        static string IdentifierNumberText(IEnumerable<AssociatedCaseDetails> associatedCases, string identifier)
        {
            var parent = associatedCases.Single(x => x.AssociatedCaseRelationshipCode == identifier);

            return parent.AssociatedCaseIdentifierNumberDetails.Single(x => x.IdentifierNumberCode == "Application").IdentifierNumberText;
        }

        [Fact]
        public void CapturesValidationMessagesFromInnography()
        {
            var validationMessagesFromInnography = new[]
            {
                "Check Application Number",
                "Check Publication Number",
                "Check Grant Number"
            };

            var innography = new ValidationResult
            {
                InnographyId = Fixture.String(),
                PublicationNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                GrantNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "21"
                },
                ApplicationNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                }
            };

            var transactionBody = XElement.Parse(_subject.Convert(innography)).Descendants(_cpaxmlNs + "TransactionBody").Single();

            var messages = transactionBody.Descendants(_cpaxmlNs + "TransactionMessageText")
                                          .Select(_ => (string) _)
                                          .ToArray();

            Assert.Equal(validationMessagesFromInnography, messages);
        }

        [Fact]
        public void ConvertsToCpaXml()
        {
            var innography = new ValidationResult
            {
                InnographyId = Fixture.String(),
                PublicationNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = SuccessMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                ApplicationDate = new MatchingFieldData
                {
                    Input = Fixture.PastDate().ToString("yyyy-MM-dd"),
                    Message = SuccessMessage,
                    PublicData = Fixture.PastDate().ToString("yyyy-MM-dd"),
                    StatusCode = "01"
                },
                GrantNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "21"
                },
                ApplicationNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                GrantDate = new MatchingFieldData
                {
                    Input = Fixture.Today().ToString("yyyy-MM-dd"),
                    Message = FailureMessage,
                    PublicData = Fixture.Today().ToString("yyyy-MM-dd"),
                    StatusCode = "01"
                },
                PublicationDate = new MatchingFieldData
                {
                    Input = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                    Message = SuccessMessage,
                    PublicData = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                    StatusCode = "01"
                },
                CountryCode = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = SuccessMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                Title = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = SuccessMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                Inventors = new MatchingFieldData
                {
                    Input = "a|b|c",
                    Message = SuccessMessage,
                    PublicData = "a|b|c",
                    StatusCode = "01"
                },
                PctNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                PriorityNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                CountryName = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                PctCountry = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                PriorityCountry = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                TypeCode = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                PriorityDate = new MatchingFieldData
                {
                    Input = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                    Message = FailureMessage,
                    PublicData = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                    StatusCode = "01"
                },
                GrantPublicationDate = new MatchingFieldData
                {
                    Input = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                    Message = FailureMessage,
                    PublicData = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                    StatusCode = "01"
                },
                PctDate = new MatchingFieldData
                {
                    Input = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                    Message = FailureMessage,
                    PublicData = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                    StatusCode = "01"
                }
            };

            var cpaxml = XElement.Parse(_subject.Convert(innography));
            var senderDetails = cpaxml.Descendants(_cpaxmlNs + "SenderDetails").Single();
            var caseDetails = cpaxml.Descendants(_cpaxmlNs + "CaseDetails").Single();

            Assert.Equal("Innography", (string) senderDetails.Element(_cpaxmlNs + "Sender"));
            Assert.Equal("Property", (string) caseDetails.Element(_cpaxmlNs + "CaseTypeCode"));

            Assert.Equal(innography.InnographyId, (string) caseDetails.Element(_cpaxmlNs + "SenderCaseIdentifier"));

            // This is decided to be 'Patent' for now because Innography hasn't yet return this value to us.
            Assert.Equal("Patent", (string) caseDetails.Element(_cpaxmlNs + "CasePropertyTypeCode"));

            Assert.Equal(innography.CountryCode.PublicData, (string) caseDetails.Element(_cpaxmlNs + "CaseCountryCode"));
            Assert.Equal(innography.Title.PublicData, (string) caseDetails.Descendants(_cpaxmlNs + "DescriptionDetails").Single().Element(_cpaxmlNs + "DescriptionText"));

            Assert.Equal(innography.ApplicationNumber.PublicData, caseDetails.GetCpaXmlNumber("Application"));
            Assert.Equal(innography.ApplicationDate.PublicData, caseDetails.GetCpaXmlDate("Application"));

            Assert.Equal(innography.PublicationNumber.PublicData, caseDetails.GetCpaXmlNumber("Publication"));
            Assert.Equal(innography.PublicationDate.PublicData, caseDetails.GetCpaXmlDate("Publication"));

            Assert.Equal(innography.GrantNumber.PublicData, caseDetails.GetCpaXmlNumber("Registration/Grant"));
            Assert.Equal(innography.GrantDate.PublicData, caseDetails.GetCpaXmlDate("Registration/Grant"));

            var associatedCases = caseDetails.ParseAssociatedCaseDetails().ToList();

            var pct = associatedCases.Single(x => x.AssociatedCaseRelationshipCode == "PCT APPLICATION");
            var pctNumber = pct.AssociatedCaseIdentifierNumberDetails.Single(x => x.IdentifierNumberCode == "Application").IdentifierNumberText;
            Assert.Equal(innography.PctNumber.GetPublicValue(), pctNumber);
            Assert.Equal(innography.PctDate.GetPublicValue(), pct.AssociatedCaseEventDetails.Single(x => x.EventCode == "Application").EventDate);

            var parent = associatedCases.Single(x => x.AssociatedCaseRelationshipCode == "PRIORITY");
            var parentNumber = IdentifierNumberText(associatedCases, "PRIORITY");
            Assert.Equal(innography.PriorityNumber.PublicData, parentNumber);
            Assert.Equal(innography.PriorityDate.PublicData, parent.AssociatedCaseEventDetails.Single(x => x.EventCode == "Application").EventDate);

            Assert.Equal(innography.GrantPublicationDate.PublicData, caseDetails.GetCpaXmlEvent("PUBLICATION OF GRANT", "EventDate"));

            Assert.Equal(new[] {"a", "b", "c"}, caseDetails.GetCpaXmlFreeFormatNames("Inventor"));
        }

        [Fact]
        public void ShouldNotIncludePriorityDetailsIfBothSidesEmpty()
        {
            var innography = new ValidationResult
            {
                InnographyId = Fixture.String(),
                PriorityNumber = new MatchingFieldData
                {
                    Input = string.Empty,
                    Message = FailureMessage,
                    PublicData = string.Empty,
                    StatusCode = "11"
                },
                PriorityCountry = new MatchingFieldData
                {
                    Input = string.Empty,
                    Message = FailureMessage,
                    PublicData = string.Empty,
                    StatusCode = "11"
                },
                PriorityDate = new MatchingFieldData
                {
                    Input = string.Empty,
                    Message = FailureMessage,
                    PublicData = string.Empty,
                    StatusCode = "11"
                }
            };

            var cpaXml = XElement.Parse(_subject.Convert(innography));
            var caseDetails = cpaXml.Descendants(_cpaxmlNs + "CaseDetails").Single();

            var associatedCases = caseDetails.ParseAssociatedCaseDetails().ToList();

            Assert.DoesNotContain(associatedCases, x => x.AssociatedCaseRelationshipCode.EndsWith("PRIORITY"));
        }

        [Fact]
        public void ShouldNotIncludePctDetailsIfBothSidesEmpty()
        {
            var innography = new ValidationResult
            {
                InnographyId = Fixture.String(),
                PctNumber = new MatchingFieldData
                {
                    Input = string.Empty,
                    Message = FailureMessage,
                    PublicData = string.Empty,
                    StatusCode = "11"
                },
                PctCountry = new MatchingFieldData
                {
                    Input = string.Empty,
                    Message = FailureMessage,
                    PublicData = string.Empty,
                    StatusCode = "11"
                },
                PctDate = new MatchingFieldData
                {
                    Input = string.Empty,
                    Message = FailureMessage,
                    PublicData = string.Empty,
                    StatusCode = "11"
                }
            };

            var cpaXml = XElement.Parse(_subject.Convert(innography));
            var caseDetails = cpaXml.Descendants(_cpaxmlNs + "CaseDetails").Single();

            var associatedCases = caseDetails.ParseAssociatedCaseDetails().ToList();

            Assert.DoesNotContain(associatedCases, x => x.AssociatedCaseRelationshipCode.EndsWith("PCT APPLICATION"));
        }

        [Fact]
        public void ShouldRecordPriorityInputAndVerificationStatus()
        {
            var innography = new ValidationResult
            {
                InnographyId = Fixture.String(),
                PriorityNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = Fixture.String()
                },
                PriorityCountry = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = SuccessMessage,
                    PublicData = Fixture.String(),
                    StatusCode = Fixture.String()
                },
                PriorityDate = new MatchingFieldData
                {
                    Input = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                    Message = FailureMessage,
                    PublicData = Fixture.Today().ToString("yyyy-MM-dd"),
                    StatusCode = Fixture.String()
                }
            };

            var expectedCaseComment = $"CountryCodeStatus:{innography.PriorityCountry.Message};OfficialNumberStatus:{innography.PriorityNumber.Message};EventDateStatus:{innography.PriorityDate.Message}";
            
            var cpaXml = XElement.Parse(_subject.Convert(innography));
            var caseDetails = cpaXml.Descendants(_cpaxmlNs + "CaseDetails").Single();

            var associatedCases = caseDetails.ParseAssociatedCaseDetails().ToList();

            var dvInput = associatedCases.Single(_ => _.AssociatedCaseRelationshipCode == "[DV]PRIORITY");
            var dvPublicData = associatedCases.Single(_ => _.AssociatedCaseRelationshipCode == "PRIORITY");

            Assert.Equal(expectedCaseComment, dvInput.AssociatedCaseComment);
            Assert.Equal(innography.PriorityNumber.Input, dvInput.OfficialNumber());
            Assert.Equal(innography.PriorityCountry.Input, dvInput.AssociatedCaseCountryCode);
            Assert.Equal(innography.PriorityDate.Input, dvInput.EventDate("Application").Iso8601OrNull());

            Assert.Equal(innography.PriorityNumber.PublicData, dvPublicData.OfficialNumber());
            Assert.Equal(innography.PriorityCountry.PublicData, dvPublicData.AssociatedCaseCountryCode);
            Assert.Equal(innography.PriorityDate.PublicData, dvPublicData.EventDate("Application").Iso8601OrNull());
        }

        [Fact]
        public void ShouldRecordPctInputAndVerificationStatus()
        {
            var innography = new ValidationResult
            {
                InnographyId = Fixture.String(),
                PctNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = SuccessMessage,
                    PublicData = Fixture.String(),
                    StatusCode = Fixture.String()
                },
                PctCountry = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = Fixture.String()
                },
                PctDate = new MatchingFieldData
                {
                    Input = Fixture.PastDate().ToString("yyyy-MM-dd"),
                    Message = FailureMessage,
                    PublicData = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                    StatusCode = Fixture.String()
                }
            };

            var expectedCaseComment = $"CountryCodeStatus:{innography.PctCountry.Message};OfficialNumberStatus:{innography.PctNumber.Message};EventDateStatus:{innography.PctDate.Message}";

            var cpaXml = XElement.Parse(_subject.Convert(innography));
            var caseDetails = cpaXml.Descendants(_cpaxmlNs + "CaseDetails").Single();

            var associatedCases = caseDetails.ParseAssociatedCaseDetails().ToList();

            var dvInput = associatedCases.Single(_ => _.AssociatedCaseRelationshipCode == "[DV]PCT APPLICATION");
            var dvPublicData = associatedCases.Single(_ => _.AssociatedCaseRelationshipCode == "PCT APPLICATION");

            Assert.Equal(expectedCaseComment, dvInput.AssociatedCaseComment);
            Assert.Equal(innography.PctNumber.Input, dvInput.OfficialNumber());
            Assert.Equal(innography.PctCountry.Input, dvInput.AssociatedCaseCountryCode);
            Assert.Equal(innography.PctDate.Input, dvInput.EventDate("Application").Iso8601OrNull());

            Assert.Equal(innography.PctNumber.PublicData, dvPublicData.OfficialNumber());
            Assert.Equal(innography.PctCountry.PublicData, dvPublicData.AssociatedCaseCountryCode);
            Assert.Equal(innography.PctDate.PublicData, dvPublicData.EventDate("Application").Iso8601OrNull());
        }

        [Fact]
        public void IgnoresWhenDatesReturnedAreEmptyString()
        {
            var innography = new ValidationResult
            {
                InnographyId = Fixture.String(),
                PublicationNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                GrantNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "21"
                },
                ApplicationNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                GrantDate = new MatchingFieldData
                {
                    Input = string.Empty,
                    Message = FailureMessage,
                    PublicData = string.Empty,
                    StatusCode = "01"
                },
                CountryCode = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = SuccessMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                Title = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = SuccessMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                }
            };

            var caseDetails = XElement.Parse(_subject.Convert(innography)).Descendants(_cpaxmlNs + "CaseDetails").Single();

            Assert.Equal(innography.ApplicationNumber.PublicData, caseDetails.GetCpaXmlNumber("Application"));
            Assert.Null(caseDetails.GetCpaXmlDate("Application"));

            Assert.Equal(innography.PublicationNumber.PublicData, caseDetails.GetCpaXmlNumber("Publication"));
            Assert.Null(caseDetails.GetCpaXmlDate("Publication"));

            Assert.Equal(innography.GrantNumber.PublicData, caseDetails.GetCpaXmlNumber("Registration/Grant"));
            Assert.Null(caseDetails.GetCpaXmlDate("Registration/Grant"));
        }

        [Fact]
        public void ThrowsFormatExceptionWhenDatesReturnedAreIncorrect()
        {
            var innography = new ValidationResult
            {
                InnographyId = Fixture.String(),
                PublicationNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                GrantNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "21"
                },
                ApplicationNumber = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                Title = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = SuccessMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                },
                GrantDate = new MatchingFieldData
                {
                    Input = Fixture.String(),
                    Message = FailureMessage,
                    PublicData = Fixture.String(),
                    StatusCode = "01"
                }
            };

            Assert.Throws<FormatException>(() => { _subject.Convert(innography); });
        }
    }
}