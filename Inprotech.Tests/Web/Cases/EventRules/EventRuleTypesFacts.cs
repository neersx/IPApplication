using Inprotech.Web.Cases.EventRules;
using Xunit;

namespace Inprotech.Tests.Web.Cases.EventRules
{
    public class EventRuleTypesFacts
    {
        public class DateStyleHelperMethod : FactBase
        {
            [Theory]
            [InlineData(0, "M/d/yyyy")]
            [InlineData(1, "dd-MMM-yyyy")]
            [InlineData(2, "MMM-dd-yyyy")]
            [InlineData(3, "yyyy-MMM-dd")]
            public void ShouldReturnDateStyle(int? dateStyle, string expectedFormat)
            {
                var r = DateStyleHelper.GetDateStyle(dateStyle, "en");
                Assert.Equal(expectedFormat, r);
            }

            [Fact]
            public void ShouldReturnDateStyleForChinesCulture()
            {
                var r = DateStyleHelper.GetDateStyle(1, "zh");
                Assert.Equal("yyyy/M/d", r);
            }
        }

        public class SentenceHelperMethod : FactBase
        {
            [Theory]
            [InlineData("", "")]
            [InlineData("  Test  ,Test ", "Test,Test")]
            public void ShouldReturnSentence(string input, string output)
            {
                var r = input.MakeSentenceLike();
                Assert.Equal(output, r);
            }
        }

        public class WorkDayTypeHelperMethod : FactBase
        {
            [Theory]
            [InlineData(null, WorkDayType.NotSet)]
            [InlineData(1, WorkDayType.PreviousWorkDay)]
            [InlineData(2, WorkDayType.NextWorkDay)]
            public void ShouldReturnWorkDay(int? workDay, WorkDayType expectedFormat)
            {
                var r = WorkDayTypeHelper.ToWorkDayType(workDay);
                Assert.Equal(expectedFormat, r);
            }
        }

        public class DateOperatorHelperMethod : FactBase
        {
            [Theory]
            [InlineData(null, DateOperator.NotSet)]
            [InlineData("A", DateOperator.Add)]
            [InlineData("S", DateOperator.Subtract)]
            public void ShouldReturnDateOperator(string code, DateOperator expectedFormat)
            {
                var r = DateOperatorHelper.StringToDateOperator(code);
                Assert.Equal(expectedFormat, r);
            }
        }

        public class DateTypeHelperMethod : FactBase
        {
            [Theory]
            [InlineData(null, DateType.NotSet)]
            [InlineData(-1, DateType.NotSet)]
            [InlineData(1, DateType.EventDate)]
            [InlineData(2, DateType.DueDate)]
            [InlineData(3, DateType.EventOrDueDate)]
            public void ShouldReturnDateType(int? code, DateType expectedFormat)
            {
                var r = DateTypeHelper.ToDateType(code);
                Assert.Equal(expectedFormat, r);
            }
        }

        public class RelativeCycleHelperMethod : FactBase
        {
            [Theory]
            [InlineData(null, RelativeCycle.NotSet)]
            [InlineData(-1, RelativeCycle.NotSet)]
            [InlineData(0, RelativeCycle.CurrentCycle)]
            [InlineData(1, RelativeCycle.PreviousCycle)]
            [InlineData(4, RelativeCycle.LatestCycle)]
            public void ShouldReturnRelativeCycle(int? code, RelativeCycle expectedFormat)
            {
                var r = RelativeCycleHelper.ToRelativeCycle(code);
                Assert.Equal(expectedFormat, r);
            }
        }

        public class BooleanComparisonHelperMethod : FactBase
        {
            [Theory]
            [InlineData(null, BooleanComparison.NotSet)]
            [InlineData(-1, BooleanComparison.NotSet)]
            [InlineData("ANY", BooleanComparison.Any)]
            [InlineData("ALL", BooleanComparison.All)]
            public void ShouldReturnBooleanComparison(string code, BooleanComparison expectedFormat)
            {
                var r = BooleanComparisonHelper.StringToBooleanComparison(code);
                Assert.Equal(expectedFormat, r);
            }
        }

        public class DueDateTypeHelperMethod : FactBase
        {
            [Theory]
            [InlineData(null, DueDateType.NotSet)]
            [InlineData("E", DueDateType.Earliest)]
            [InlineData("L", DueDateType.Latest)]
            public void ShouldReturnDueDateType(string code, DueDateType expectedFormat)
            {
                var r = DueDateTypeHelper.StringToDueDateType(code);
                Assert.Equal(expectedFormat, r);
            }
        }

        public class PeriodTypeHelperMethod : FactBase
        {
            [Theory]
            [InlineData(null, PeriodType.NotSet)]
            [InlineData("D", PeriodType.Days)]
            [InlineData("Y", PeriodType.Years)]
            [InlineData("1", PeriodType.StandingInstruction_Period1)]
            [InlineData("E", PeriodType.UserEntered)]
            public void ShouldReturnPeriodType(string code, PeriodType expectedFormat)
            {
                var r = PeriodTypeHelper.StringToPeriodType(code);
                Assert.Equal(expectedFormat, r);
            }
        }

        public class FailureActionHelperMethod : FactBase
        {
            [Theory]
            [InlineData(null, FailureAction.NotSet)]
            [InlineData(-1, FailureAction.NotSet)]
            [InlineData(1, FailureAction.Error)]
            [InlineData(0, FailureAction.Warning)]
            public void ShouldReturnFailureAction(int? code, FailureAction expectedFormat)
            {
                var r = FailureActionHelper.ToFailureAction(code);
                Assert.Equal(expectedFormat, r);
            }
        }
    }
}
