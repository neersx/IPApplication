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
    public class CompareMatchingNumberEventScenarioFacts
    {
        readonly CompareMatchingNumberEventScenario _subject = new CompareMatchingNumberEventScenario();
        readonly CaseDetails _caseDetails = new CaseDetails("P", "AU");
        readonly IEnumerable<TransactionMessageDetails> _messageDetails = new TransactionMessageDetails[0];

        [Fact]
        public void AllDetailsAreReturned()
        {
            _caseDetails.EventDetails = new List<EventDetails>
            {
                new EventDetails("1")
                {
                    EventDate = "2001-01-01",
                    EventDescription = "description"
                }
            };

            _caseDetails.IdentifierNumberDetails = new List<IdentifierNumberDetails>
            {
                new IdentifierNumberDetails("1", Fixture.String())
            };

            var r = (ComparisonScenario<MatchingNumberEvent>) _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("1", r.ComparisonSource.EventCode);
            Assert.Equal("description", r.ComparisonSource.EventDescription);
            Assert.Equal(new DateTime(2001, 1, 1), r.ComparisonSource.EventDate);
        }

        [Fact]
        public void ReturnsAsManyAsNumberOfNumbers()
        {
            _caseDetails.EventDetails = new List<EventDetails>
            {
                new EventDetails("1")
            };

            _caseDetails.IdentifierNumberDetails = new List<IdentifierNumberDetails>
            {
                new IdentifierNumberDetails("1", "ABC"),
                new IdentifierNumberDetails("3", "DEF")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).Cast<ComparisonScenario<MatchingNumberEvent>>().ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("1", r.First().ComparisonSource.EventCode);
            Assert.Equal("3", r.Last().ComparisonSource.EventCode);
        }

        [Fact]
        public void ReturnsThoseWithMatchingNumber()
        {
            _caseDetails.EventDetails = new List<EventDetails>
            {
                new EventDetails("1"),
                new EventDetails("2"),
                new EventDetails("3")
            };

            _caseDetails.IdentifierNumberDetails = new List<IdentifierNumberDetails>
            {
                new IdentifierNumberDetails("1", "ABC"),
                new IdentifierNumberDetails("3", "DEF")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).Cast<ComparisonScenario<MatchingNumberEvent>>().ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("1", r.First().ComparisonSource.EventCode);
            Assert.Equal("3", r.Last().ComparisonSource.EventCode);
        }

        [Fact]
        public void ShouldReturnEventComparisonType()
        {
            _caseDetails.IdentifierNumberDetails = new List<IdentifierNumberDetails>
            {
                new IdentifierNumberDetails("1", Fixture.String())
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(ComparisonType.MatchingNumberEvents, r.Single().ComparisonType);
        }
    }
}