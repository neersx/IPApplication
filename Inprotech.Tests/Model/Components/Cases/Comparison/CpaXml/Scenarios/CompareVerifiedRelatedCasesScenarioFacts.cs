using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareVerifiedRelatedCasesScenarioFacts
    {
        readonly CompareVerifiedRelatedCasesScenario _subject = new CompareVerifiedRelatedCasesScenario();
        readonly CaseDetails _caseDetails = new CaseDetails("P", "AU");
        readonly IEnumerable<TransactionMessageDetails> _messageDetails = new TransactionMessageDetails[0];

        [Fact]
        public void AllDetailsAreReturned()
        {
            _caseDetails.AssociatedCaseDetails = new List<AssociatedCaseDetails>
            {
                new AssociatedCaseDetails("[DV]PRIORITY")
                {
                    AssociatedCaseCountryCode = "AU",
                    AssociatedCaseComment = "CountryCodeStatus:VERIFICATION_SUCCESS;EventDateStatus:VERIFICATION_FAILURE;OfficialNumberStatus:VERIFICATION_SUCCESS",
                    AssociatedCaseEventDetails = new List<EventDetails>
                    {
                        new EventDetails("Application")
                        {
                            EventDate = "2001-01-01"
                        }
                    },
                    AssociatedCaseIdentifierNumberDetails =
                        new List<IdentifierNumberDetails>
                        {
                            new IdentifierNumberDetails("Application", "12345")
                        }
                },
                new AssociatedCaseDetails("PRIORITY")
                {
                    AssociatedCaseCountryCode = "AU",
                    AssociatedCaseEventDetails = new List<EventDetails>
                    {
                        new EventDetails("Application")
                        {
                            EventDate = "2000-08-08"
                        }
                    },
                    AssociatedCaseIdentifierNumberDetails =
                        new List<IdentifierNumberDetails>
                        {
                            new IdentifierNumberDetails("Application", "12345")
                        }
                }
            };

            var r = (ComparisonScenario<VerifiedRelatedCase>) _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("AU", r.ComparisonSource.InputCountryCode);
            Assert.Equal("AU", r.ComparisonSource.CountryCode);

            Assert.Equal(new DateTime(2001, 1, 1), r.ComparisonSource.InputEventDate);
            Assert.Equal(new DateTime(2000, 8, 8), r.ComparisonSource.EventDate);

            Assert.Equal("12345", r.ComparisonSource.InputOfficialNumber);
            Assert.Equal("12345", r.ComparisonSource.OfficialNumber);

            Assert.True(r.ComparisonSource.CountryCodeVerified);
            Assert.False(r.ComparisonSource.EventDateVerified);
            Assert.True(r.ComparisonSource.OfficialNumberVerified);
        }

        [Fact]
        public void IsWrappedAroundComparisonScenarioForRelatedCase()
        {
            _caseDetails.AssociatedCaseDetails = new List<AssociatedCaseDetails>
            {
                new AssociatedCaseDetails("BAS")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.IsType<ComparisonScenario<VerifiedRelatedCase>>(r.Single());
        }

        [Fact]
        public void ShouldReturnsGroupedVerifiedRelatedCases()
        {
            var priorityCases = new List<AssociatedCaseDetails>
            {
                new AssociatedCaseDetails("[DV]PRIORITY")
                {
                    AssociatedCaseCountryCode = Fixture.String(),
                    AssociatedCaseComment = "CountryCodeStatus:VERIFICATION_SUCCESS;EventDateStatus:VERIFICATION_SUCCESS;OfficialNumberStatus:VERIFICATION_SUCCESS",
                    AssociatedCaseEventDetails = new List<EventDetails>()
                    {
                        new EventDetails(Fixture.String())
                        {
                            EventDate = Fixture.Date().ToString("yyyy-MM-dd")
                        }
                    }
                },
                new AssociatedCaseDetails("PRIORITY")
                {
                    AssociatedCaseCountryCode = Fixture.String(),
                    AssociatedCaseComment = Fixture.String(),
                    AssociatedCaseEventDetails = new List<EventDetails>()
                    {
                        new EventDetails(Fixture.String())
                        {
                            EventDate = Fixture.Date().ToString("yyyy-MM-dd")
                        }
                    }
                },
            };
            var pctCases = new List<AssociatedCaseDetails>
            {
                new AssociatedCaseDetails("[DV]PCT APPLICATION")
                {
                    AssociatedCaseCountryCode = Fixture.String(),
                    AssociatedCaseComment = "CountryCodeStatus:VERIFICATION_FAILURE;EventDateStatus:VERIFICATION_FAILURE;OfficialNumberStatus:VERIFICATION_FAILURE",
                    AssociatedCaseEventDetails = new List<EventDetails>()
                    {
                        new EventDetails(Fixture.String())
                        {
                            EventDate = Fixture.Date().ToString("yyyy-MM-dd")
                        }
                    }
                },
                new AssociatedCaseDetails("PCT APPLICATION")
                {
                    AssociatedCaseCountryCode = Fixture.String(),
                    AssociatedCaseComment = Fixture.String(),
                    AssociatedCaseEventDetails = new List<EventDetails>()
                    {
                        new EventDetails(Fixture.String())
                        {
                            EventDate = Fixture.Date().ToString("yyyy-MM-dd")
                        }
                    }
                },
            };
            _caseDetails.AssociatedCaseDetails = priorityCases.Union(pctCases).ToList();

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(2, r.Length);

            var priority = ((ComparisonScenario<VerifiedRelatedCase>)r.Last()).ComparisonSource;
            Assert.Equal(priority.CountryCode, priorityCases.Last().AssociatedCaseCountryCode);
            Assert.Equal(priority.Description, priorityCases.Last().AssociatedCaseComment);
            Assert.Equal(priority.OfficialNumber, priorityCases.Last().OfficialNumber());
            Assert.Equal(priority.EventDate?.ToString("yyyy-MM-dd"), priorityCases.Last().AssociatedCaseEventDetails.First().EventDate);

            Assert.Equal(priority.InputCountryCode, priorityCases.First().AssociatedCaseCountryCode);
            Assert.Equal(priority.InputOfficialNumber, priorityCases.First().OfficialNumber());
            Assert.Equal(priority.InputEventDate?.ToString("yyyy-MM-dd"), priorityCases.First().AssociatedCaseEventDetails.Last().EventDate);
            Assert.True(priority.EventDateVerified);
            Assert.True(priority.CountryCodeVerified);
            Assert.True(priority.OfficialNumberVerified);

            var pct = ((ComparisonScenario<VerifiedRelatedCase>)r.First()).ComparisonSource;
            Assert.Equal(pct.CountryCode, pctCases.Last().AssociatedCaseCountryCode);
            Assert.Equal(pct.Description, pctCases.Last().AssociatedCaseComment);
            Assert.Equal(pct.OfficialNumber, pctCases.Last().OfficialNumber());
            Assert.Equal(pct.EventDate?.ToString("yyyy-MM-dd"), pctCases.Last().AssociatedCaseEventDetails.First().EventDate);

            Assert.Equal(pct.InputCountryCode, pctCases.First().AssociatedCaseCountryCode);
            Assert.Equal(pct.InputOfficialNumber, pctCases.First().OfficialNumber());
            Assert.Equal(pct.InputEventDate?.ToString("yyyy-MM-dd"), pctCases.First().AssociatedCaseEventDetails.Last().EventDate);
            Assert.False(pct.EventDateVerified);
            Assert.False(pct.CountryCodeVerified);
            Assert.False(pct.OfficialNumberVerified);

        }

        [Fact]
        public void ShouldReturnRelatedCaseComparisonType()
        {
            _caseDetails.AssociatedCaseDetails = new List<AssociatedCaseDetails>
            {
                new AssociatedCaseDetails("BAS")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(ComparisonType.VerifiedRelatedCases, r.Single().ComparisonType);
        }

        [Fact]
        public void ShouldAllowForInnography()
        {
            Assert.True(_subject.IsAllowed("IPOneData"));
        }

        [Theory]
        [InlineData("EPO")]
        [InlineData("FILE")]
        public void ShouldNotAllowedForOthers(string otherSource)
        {
            Assert.False(_subject.IsAllowed(otherSource));
        }
    }
}