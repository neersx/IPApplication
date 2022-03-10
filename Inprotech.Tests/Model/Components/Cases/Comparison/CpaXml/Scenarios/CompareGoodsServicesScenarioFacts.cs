using System.Collections.Generic;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareGoodsServicesScenarioFacts
    {
        readonly CompareGoodsServicesScenario _subject = new CompareGoodsServicesScenario();
        readonly CaseDetails _caseDetails = new CaseDetails("T", "US");
        readonly IEnumerable<TransactionMessageDetails> _messageDetails = new TransactionMessageDetails[0];

        [Fact]
        public void AllDetailsAreReturned()
        {
            _caseDetails.GoodsServicesDetails = new List<GoodsServicesDetails>
            {
                new GoodsServicesDetails
                {
                    ClassDescriptionDetails = new ClassDescriptionDetails
                    {
                        ClassDescriptions = new List<ClassDescription>
                        {
                            new ClassDescription("03", "Computer Goods", "20010101", "20030303")
                        }
                    }
                }
            };

            var r = (ComparisonScenario<GoodsServices>) _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("03", r.ComparisonSource.Class);
            Assert.Equal("20010101", r.ComparisonSource.FirstUsedDate);
            Assert.Equal("20030303", r.ComparisonSource.FirstUsedDateInCommerce);
            Assert.Equal("Computer Goods", r.ComparisonSource.Text);
        }

        [Fact]
        public void IsWrappedAroundComparisonScenarioForGoodsServices()
        {
            _caseDetails.GoodsServicesDetails = new List<GoodsServicesDetails>
            {
                new GoodsServicesDetails()
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.IsType<ComparisonScenario<GoodsServices>>(r.Single());
        }

        [Fact]
        public void ReturnsAllGoodsServices()
        {
            _caseDetails.GoodsServicesDetails = new List<GoodsServicesDetails>
            {
                new GoodsServicesDetails(),
                new GoodsServicesDetails()
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(2, r.Count());
        }

        [Fact]
        public void ShouldReturnGoodsServicesComparisonType()
        {
            _caseDetails.GoodsServicesDetails = new List<GoodsServicesDetails>
            {
                new GoodsServicesDetails()
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(ComparisonType.GoodsServices, r.Single().ComparisonType);
        }
        
        [Fact]
        public void AllowsAllSourceSystem()
        {
            Assert.True(_subject.IsAllowed(Fixture.String()));
        }
    }
}