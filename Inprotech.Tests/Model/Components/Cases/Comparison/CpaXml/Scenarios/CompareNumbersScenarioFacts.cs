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
    public class CompareNumbersScenarioFacts
    {
        readonly CompareNumbersScenario _subject = new CompareNumbersScenario();
        readonly CaseDetails _caseDetails = new CaseDetails("P", "AU");
        readonly IEnumerable<TransactionMessageDetails> _messageDetails = new TransactionMessageDetails[0];

        [Fact]
        public void AllDetailsAreReturned()
        {
            _caseDetails.IdentifierNumberDetails = new List<IdentifierNumberDetails>
            {
                new IdentifierNumberDetails("Application", "12345")
            };

            var r = (ComparisonScenario<OfficialNumber>) _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("Application", r.ComparisonSource.Code);
            Assert.Equal("Application", r.ComparisonSource.NumberType);
            Assert.Equal("12345", r.ComparisonSource.Number);
            Assert.Null(r.ComparisonSource.EventDate);
        }

        [Fact]
        public void CopyOfDetailsIsReturned()
        {
            _caseDetails.IdentifierNumberDetails = new List<IdentifierNumberDetails>
            {
                new IdentifierNumberDetails("Application", "12345")
            };

            _caseDetails.EventDetails = new List<EventDetails>
            {
                new EventDetails("Application")
                {
                    EventDate = "2001-01-01"
                }
            };

            var r = (ComparisonScenario<OfficialNumber>) _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal(r.Mapped.Number, r.ComparisonSource.Number);
            Assert.Equal(r.Mapped.NumberType, r.ComparisonSource.NumberType);
            Assert.Equal(r.Mapped.Code, r.ComparisonSource.Code);
            Assert.Equal(r.Mapped.EventDate, r.ComparisonSource.EventDate);
        }

        [Fact]
        public void IsWrappedAroundComparisonScenarioForNumbers()
        {
            _caseDetails.IdentifierNumberDetails = new List<IdentifierNumberDetails>
            {
                new IdentifierNumberDetails("Application", "12345")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.IsType<ComparisonScenario<OfficialNumber>>(r.Single());
        }

        [Fact]
        public void ReturnsAllNumbers()
        {
            _caseDetails.IdentifierNumberDetails = new List<IdentifierNumberDetails>
            {
                new IdentifierNumberDetails("Application", "12345"),
                new IdentifierNumberDetails("Publication", "23456")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(2, r.Length);
        }

        [Fact]
        public void ReturnsMatchingEventDate()
        {
            _caseDetails.IdentifierNumberDetails = new List<IdentifierNumberDetails>
            {
                new IdentifierNumberDetails("Application", "12345")
            };

            _caseDetails.EventDetails = new List<EventDetails>
            {
                new EventDetails("Application")
                {
                    EventDate = "2001-01-01"
                }
            };

            var r = (ComparisonScenario<OfficialNumber>) _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("Application", r.ComparisonSource.Code);
            Assert.Equal("Application", r.ComparisonSource.NumberType);
            Assert.Equal("12345", r.ComparisonSource.Number);
            Assert.Equal(new DateTime(2001, 1, 1), r.ComparisonSource.EventDate);
        }

        [Fact]
        public void ShouldReturnNumberComparisonType()
        {
            _caseDetails.IdentifierNumberDetails = new List<IdentifierNumberDetails>
            {
                new IdentifierNumberDetails("Application", "12345")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(ComparisonType.OfficialNumbers, r.Single().ComparisonType);
        }

        [Fact]
        public void AllowsAllSourceSystem()
        {
            Assert.True(_subject.IsAllowed(Fixture.String()));
        }
    }
}