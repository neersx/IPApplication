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
    public class CompareEventsScenarioFacts
    {
        readonly CompareEventsScenario _subject = new CompareEventsScenario();
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
                    EventDescription = "description",
                    EventText = "text"
                }
            };

            var r = (ComparisonScenario<Event>) _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("1", r.ComparisonSource.EventCode);
            Assert.Equal("description", r.ComparisonSource.EventDescription);
            Assert.Equal("text", r.ComparisonSource.EventText);
            Assert.Equal(new DateTime(2001, 1, 1), r.ComparisonSource.EventDate);
        }

        [Fact]
        public void CopyOfDetailsIsReturned()
        {
            _caseDetails.EventDetails = new List<EventDetails>
            {
                new EventDetails("1")
                {
                    EventDate = "2001-01-01",
                    EventDescription = "description",
                    EventText = "text"
                }
            };

            var r = (ComparisonScenario<Event>) _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal(r.Mapped.EventCode, r.ComparisonSource.EventCode);
            Assert.Equal(r.Mapped.EventDescription, r.ComparisonSource.EventDescription);
            Assert.Equal(r.Mapped.EventText, r.ComparisonSource.EventText);
            Assert.Equal(r.Mapped.EventDate, r.ComparisonSource.EventDate);
        }

        [Fact]
        public void IsWrappedAroundComparisonScenarioForEvent()
        {
            _caseDetails.EventDetails = new List<EventDetails>
            {
                new EventDetails("1")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.IsType<ComparisonScenario<Event>>(r.Single());
        }

        [Fact]
        public void ReturnsAllEvents()
        {
            _caseDetails.EventDetails = new List<EventDetails>
            {
                new EventDetails("1"),
                new EventDetails("2")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(2, r.Count());
        }

        [Fact]
        public void ShouldReturnEventComparisonType()
        {
            _caseDetails.EventDetails = new List<EventDetails>
            {
                new EventDetails("1")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(ComparisonType.Events, r.Single().ComparisonType);
        }

        [Fact]
        public void AllowsAllSourceSystem()
        {
            Assert.True(_subject.IsAllowed(Fixture.String()));
        }
    }
}