using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.EventRules
{
    public class DueDateCalculationServiceFacts : FactBase
    {
        EventViewRuleDetails SetupData()
        {
            var caseId = Fixture.Integer();
            var caseRef = Fixture.String();
            var eventId = Fixture.Integer();
            var fromEventId = Fixture.Integer();

            return new EventViewRuleDetails
            {
                CaseId = caseId,
                EventId = eventId,
                Cycle = 1,
                CaseReference = caseRef,
                Action = Fixture.String("A"),
                EventControlDetails = new EventControlDetails
                {
                    Irn = caseRef,
                    CriteriaNo = Fixture.Integer(),
                    EventNo = eventId,
                    WhichDueDate = "E",
                    CompareBoolean = "Any",
                    SaveDueDate = true,
                    ExtendPeriod = 10,
                    ExtendPeriodType = "M",
                    RecalcEventDate = true,
                    InstructionType = Fixture.String(),
                    InstructionFlag = Fixture.String()
                },
                DueDateCalculationDetails = new List<DueDateCalculationDetails>
                {
                    new DueDateCalculationDetails
                    {
                        CaseId = caseId,
                        FromEvent = fromEventId,
                        FromDate = Fixture.Date(),
                        FromEventDesc = Fixture.String(),
                        RelativeCycle = Fixture.Short(),
                        Operator = "A",
                        DeadlinePeriod = 100,
                        PeriodType = "D",
                        EventDateFlag = 1,
                        MustExist = true,
                        WorkDay = 0,
                        Adjustment = Fixture.String("Adj")
                    }
                },
                DateComparisonDetails = new List<DateComparisonDetails>
                {
                    new DateComparisonDetails
                    {
                        CaseId = caseId,
                        FromEvent = Fixture.Integer(),
                        FromEventDesc = Fixture.String(),
                        RelativeCycle = 2,
                        EventDateFlag = 1,
                        Comparison = "=",
                        CompareEvent = Fixture.Integer(),
                        CompareEventDesc = Fixture.String(),
                        CompareCycle = 1,
                        CompareSystemDate = false,
                        CompareEventFlag = 1
                    },
                    new DateComparisonDetails
                    {
                        CaseId = caseId,
                        FromEvent = Fixture.Integer(),
                        FromEventDesc = Fixture.String(),
                        RelativeCycle = 2,
                        EventDateFlag = 1,
                        Comparison = ">=",
                        CompareEvent = Fixture.Integer(),
                        CompareEventDesc = Fixture.String(),
                        ComparisonDate = Fixture.Date(),
                        CompareCycle = 1,
                        CompareSystemDate = true
                    }
                },
                RelatedEventDetails = new List<RelatedEventDetails>
                {
                    new RelatedEventDetails
                    {
                        RelatedEvent = Fixture.Integer(),
                        RelatedEventDesc = Fixture.String(),
                        SatisfyEvent = true,
                        RelativeCycle = 3
                    }
                }
            };
        }
        [Fact]
        public void ShouldReturnFormattedDueDatCalculations()
        {
            var f = new DueDateCalculationServiceFixture();
            var details = SetupData();
            var desc = Fixture.String();

            f.EventRulesHelper.PeriodTypeToLocalizedString(Arg.Any<short?>(), Arg.Any<string>(), Arg.Any<string[]>()).Returns("month(s)");
            f.EventRulesHelper.PeriodTypeToLocalizedString(Arg.Any<short?>(), Arg.Any<PeriodType>(), Arg.Any<string[]>()).Returns("day(s)");
            f.EventRulesHelper.DateTypeToLocalizedString(Arg.Any<int>(), Arg.Any<string[]>()).Returns("event date");
            f.EventRulesHelper.RelativeCycleToLocalizedString(Arg.Any<int>(), Arg.Any<string[]>()).Returns("next cycle");
            f.EventRulesHelper.StringToComparisonOperator(Arg.Any<string>()).Returns(ComparisonOperator.EqualTo);
            f.EventRulesHelper.ComparisonOperatorToSymbol(Arg.Any<string>(), Arg.Any<string[]>()).Returns("=");

            f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns(desc);
            var r = f.Subject.GetDueDateCalculations(details);

            var ddExpectedCalc = details.DueDateCalculationDetails.First();
            var ddCalc = r.DueDateCalculation.First();
            Assert.Equal(1, r.DueDateCalculation.Count());
            Assert.Equal(ddExpectedCalc.FromEvent, ddCalc.EventKey);
            Assert.Equal(ddExpectedCalc.CaseId, ddCalc.CaseKey);
            Assert.Equal(details.EventControlDetails?.Irn, ddCalc.CaseReference);
            Assert.Equal(ddExpectedCalc.FromCycle, ddCalc.Cycle);
            Assert.Equal(ddExpectedCalc.MustExist, ddCalc.MustExist);
            Assert.True(ddCalc.CalculatedFromLabel.Contains("calculatedFromDate"));
            Assert.Equal(ddExpectedCalc.FromDate?.ToString("dd-MMM-yyyy"), ddCalc.FromDateFormatted);
            Assert.Equal($"{ddExpectedCalc.FromEventDesc} [next cycle] event date + month(s) {desc} \"{ddExpectedCalc.Adjustment}\"", ddCalc.FormattedDescription);

            var ddCompareExpected1 = details.DateComparisonDetails.First();
            var ddCompareExpected2 = details.DateComparisonDetails.Last();
            var ddCompare = r.DueDateComparison.ToList();
            Assert.Equal(2, ddCompare.Count);
            Assert.Equal(desc, r.DueDateComparisonInfo);
            Assert.Equal(ddCompareExpected1.FromEvent, ddCompare[0].LeftHandSideEventKey);
            Assert.Equal($"{ddCompareExpected1.FromEventDesc} [next cycle] event date", ddCompare[0].LeftHandSide);
            Assert.Equal("=", ddCompare[0].Comparison);
            Assert.Equal(ddCompareExpected1.CompareEvent, ddCompare[0].RightHandSideEventKey);
            Assert.Equal($"{ddCompareExpected1.CompareEventDesc} [next cycle] event date", ddCompare[0].RightHandSide);

            Assert.Equal($"{ddCompareExpected2.FromEventDesc} [next cycle] event date", ddCompare[1].LeftHandSide);
            Assert.Equal($"{desc}", ddCompare[1].RightHandSide);

            var relEvent1 = details.RelatedEventDetails.First();
            var relEvents = r.DueDateSatisfiedBy.ToList();
            Assert.Equal(1, relEvents.Count);
            Assert.Equal(relEvent1.RelatedEvent, relEvents[0].EventKey);
            Assert.Equal($"{relEvent1.RelatedEventDesc} [next cycle]", relEvents[0].FormattedDescription);
            
            Assert.Equal("day(s)", r.ExtensionInfo);
            Assert.True(r.HasSaveDueDateInfo);
            Assert.True(r.HasRecalculateInfo);
        }

        [Fact]
        public void ShouldReturnNullWhenNoDueDateCalculations()
        {
            var details = new EventViewRuleDetails
            {
                DueDateCalculationDetails = new List<DueDateCalculationDetails>(),
                RelatedEventDetails = new List<RelatedEventDetails>
                {
                    new RelatedEventDetails()
                }
            };
            var f = new DueDateCalculationServiceFixture();
            var r = f.Subject.GetDueDateCalculations(details);
            Assert.Null(r);
        }
    }

    public class DueDateCalculationServiceFixture : IFixture<DueDateCalculationService>
    {
        public IStaticTranslator StaticTranslator { get; }
        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public IEventRulesHelper EventRulesHelper { get; }
        public ISiteControlReader SiteControlReader { get; set; }

        public DueDateCalculationServiceFixture()
        {
            StaticTranslator = Substitute.For<IStaticTranslator>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            EventRulesHelper = Substitute.For<IEventRulesHelper>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Subject = new DueDateCalculationService(PreferredCultureResolver, StaticTranslator, SiteControlReader, EventRulesHelper);

            PreferredCultureResolver.Resolve().Returns("en");
            PreferredCultureResolver.ResolveAll().Returns(new[] {"en"});
            SiteControlReader.Read<int>(SiteControls.DateStyle).Returns(1);
        }
        public DueDateCalculationService Subject { get; }
    }
}
