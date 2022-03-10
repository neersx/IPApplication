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
    public class CompareRelatedCasesScenarioFacts
    {
        readonly CompareRelatedCasesScenario _subject = new CompareRelatedCasesScenario();
        readonly CaseDetails _caseDetails = new CaseDetails("P", "AU");
        readonly IEnumerable<TransactionMessageDetails> _messageDetails = new TransactionMessageDetails[0];

        [Fact]
        public void AllDetailsAreReturned()
        {
            _caseDetails.AssociatedCaseDetails = new List<AssociatedCaseDetails>
            {
                new AssociatedCaseDetails("BAS")
                {
                    AssociatedCaseCountryCode = "AU",
                    AssociatedCaseComment = "Comment",
                    AssociatedCaseEventDetails = new List<EventDetails>
                    {
                        new EventDetails("Priority")
                        {
                            EventDate = "2001-01-01"
                        }
                    },
                    AssociatedCaseIdentifierNumberDetails =
                        new List<IdentifierNumberDetails>
                        {
                            new IdentifierNumberDetails("Priority", "12345"),
                            new IdentifierNumberDetails("Registration/Grant", "56789")
                        },
                    AssociatedCaseStatus = "Status"
                }
            };

            var r = (ComparisonScenario<RelatedCase>) _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("Comment", r.ComparisonSource.Description);
            Assert.Equal("AU", r.ComparisonSource.CountryCode);
            Assert.Equal(new DateTime(2001, 1, 1), r.ComparisonSource.EventDate);
            Assert.Equal("56789", r.ComparisonSource.RegistrationNumber);
            Assert.Equal("12345", r.ComparisonSource.OfficialNumber);
            Assert.Equal("Status", r.ComparisonSource.Status);
        }

        [Fact]
        public void IsWrappedAroundComparisonScenarioForRelatedCase()
        {
            _caseDetails.AssociatedCaseDetails = new List<AssociatedCaseDetails>
            {
                new AssociatedCaseDetails("BAS")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.IsType<ComparisonScenario<RelatedCase>>(r.Single());
        }

        [Fact]
        public void ReturnsAllRelatedCases()
        {
            _caseDetails.AssociatedCaseDetails = new List<AssociatedCaseDetails>
            {
                new AssociatedCaseDetails("BAS"),
                new AssociatedCaseDetails("DIV")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(2, r.Length);
        }

        [Fact]
        public void ReturnsCodeIfCommentEmpty()
        {
            _caseDetails.AssociatedCaseDetails = new List<AssociatedCaseDetails>
            {
                new AssociatedCaseDetails("BAS")
                {
                    AssociatedCaseComment = null
                }
            };

            var r = (ComparisonScenario<RelatedCase>) _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("BAS", r.ComparisonSource.Description);
        }

        [Fact]
        public void ShouldReturnRelatedCaseComparisonType()
        {
            _caseDetails.AssociatedCaseDetails = new List<AssociatedCaseDetails>
            {
                new AssociatedCaseDetails("BAS")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(ComparisonType.RelatedCases, r.Single().ComparisonType);
        }
        
        [Fact]
        public void AllowsAllSourceSystemExceptIpOneData()
        {
            Assert.True(_subject.IsAllowed(Fixture.String()));
            Assert.False(_subject.IsAllowed("IPOneData"));
        }
    }
}