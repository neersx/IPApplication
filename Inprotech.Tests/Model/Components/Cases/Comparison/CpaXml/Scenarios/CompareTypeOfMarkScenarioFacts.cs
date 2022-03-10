using System.Collections.Generic;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareTypeOfMarkScenarioFacts
    {
        readonly CompareTypeOfMarkScenerio _subject = new CompareTypeOfMarkScenerio();
        readonly CaseDetails _caseDetails = new CaseDetails("Trademark", "US");
        readonly IEnumerable<TransactionMessageDetails> _messageDetails = new TransactionMessageDetails[0];

        [Fact]
        public void AllowsAllSourceSystem()
        {
            Assert.True(_subject.IsAllowed(Fixture.String()));
        }

        [Fact]
        public void ReturnsTypeOfMarkWhenSetInCaseDetails()
        {
            _caseDetails.TypeOfMark = "BLOCK LETTERS";

            var r = _subject.Resolve(_caseDetails, _messageDetails)
                            .OfType<ComparisonScenario<TypeOfMark>>().ToArray();

            Assert.True(r.Any());
            Assert.Equal("BLOCK LETTERS", r.Single().ComparisonSource.Description);
        }

        [Fact]
        public void DoesNotReturnsScenarioWhenNotSetInCaseDetails()
        {
            _caseDetails.TypeOfMark = null;

            var r = _subject.Resolve(_caseDetails, _messageDetails)
                            .OfType<ComparisonScenario<TypeOfMark>>().ToArray();

            Assert.False(r.Any());
        }
    }
}