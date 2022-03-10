using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.EventRules
{
    public class DatesLogicServiceFacts : FactBase
    {
        [Fact]
        public void ShouldReturnDatesLogicDetail()
        {
            var details = new List<DatesLogicDetails>
            {
                new DatesLogicDetails
                {
                    DateType = 1,
                    Operator = ">",
                    CompareEvent = Fixture.Integer(),
                    CompareEventDesc = Fixture.String(),
                    MustExist = true,
                    RelativeCycle = Fixture.Short(),
                    ComparisonEventNo = Fixture.Integer(),
                    ComparisonCycleNo = Fixture.Short(),
                    ComparisonDate = Fixture.Date(),
                    CaseRelationship = "CTP",
                    CompareRelationship = Fixture.String(),
                    CompareDateType = Fixture.Integer(),
                    DisplayErrorFlag = 0,
                    ErrorMessage = Fixture.String()
                },
                new DatesLogicDetails
                {
                    DateType = 1,
                    Operator = "<=",
                    CompareEvent = Fixture.Integer(),
                    CompareEventDesc = Fixture.String(),
                    MustExist = false,
                    RelativeCycle = Fixture.Short(),
                    ComparisonEventNo = Fixture.Integer(),
                    ComparisonCycleNo = Fixture.Short(),
                    ComparisonDate = Fixture.Date(),
                    CompareDateType = Fixture.Integer(),
                    DisplayErrorFlag = 1,
                    ErrorMessage = Fixture.String()
                }
            };

            var f = new DatesLogicServiceFixture();
            f.EventRulesHelper.DateTypeToLocalizedString(Arg.Any<int>(), Arg.Any<string[]>()).Returns("event date");
            f.EventRulesHelper.RelativeCycleToLocalizedString(Arg.Any<int>(), Arg.Any<string[]>()).Returns("next cycle");
            f.EventRulesHelper.ComparisonOperatorToSymbol(Arg.Any<string>(), Arg.Any<string[]>()).Returns("=");

            const string datesLogicDesc = "Entered {0} should be {1} {2} {3}";
            const string fromRelationship = "from Relationship {0} {1}";
            const string dateTranslate = "caseview.eventRules.dateslogic.";
            f.StaticTranslator.Translate(dateTranslate + "mustExist", Arg.Any<IEnumerable<string>>()).Returns("must exists");
            f.StaticTranslator.Translate(dateTranslate + "fromRelationship", Arg.Any<IEnumerable<string>>()).Returns(fromRelationship);
            f.StaticTranslator.Translate(dateTranslate + "failureAction_Warning", Arg.Any<IEnumerable<string>>()).Returns("warning");
            f.StaticTranslator.Translate(dateTranslate + "failureAction_Error", Arg.Any<IEnumerable<string>>()).Returns("error");
            f.StaticTranslator.Translate(dateTranslate + "dateValidation", Arg.Any<IEnumerable<string>>()).Returns(datesLogicDesc);
            
            var r = f.Subject.GetDatesLogicDetails(details).ToArray();
            Assert.Equal(2, r.Length);
            Assert.Equal(details[0].ErrorMessage, r[0].MessageDisplayed);
            Assert.Equal(FailureAction.Warning.ToString(), r[0].FailureActionType);
            Assert.Equal("warning", r[0].TestFailureAction);
            var relationshipText = string.Format(fromRelationship, "\"" + details[0].CompareRelationship + "\"", "must exists");
            Assert.Equal(string.Format(datesLogicDesc, "event date", "=", $"{details[0].CompareEventDesc} [next cycle] event date", relationshipText), r[0].FormattedDescription);

            Assert.Equal(details[1].ErrorMessage, r[1].MessageDisplayed);
            Assert.Equal(FailureAction.Error.ToString(), r[1].FailureActionType);
            Assert.Equal("error", r[1].TestFailureAction);
            Assert.Equal(string.Format(datesLogicDesc, "event date", "=", $"{details[1].CompareEventDesc} [next cycle] event date", string.Empty).MakeSentenceLike(), r[1].FormattedDescription);
        }
    }

    public class DatesLogicServiceFixture : IFixture<DatesLogicService>
    {
        public DatesLogicServiceFixture()
        {
            StaticTranslator = Substitute.For<IStaticTranslator>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            EventRulesHelper = Substitute.For<IEventRulesHelper>();
            Subject = new DatesLogicService(PreferredCultureResolver, StaticTranslator, EventRulesHelper);
        }

        public IStaticTranslator StaticTranslator { get; }
        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public IEventRulesHelper EventRulesHelper { get; }
        public DatesLogicService Subject { get; }
    }
}