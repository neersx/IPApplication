using System.Collections.Generic;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.EventRules
{
    public class EventRulesHelperFacts
    {
        public class PeriodTypeToLocalizedStringMethod : FactBase
        {
            [Fact]
            public void ShouldReturnPeriodTypeToLocalizedString()
            {
                var f = new EventRulesHelperFixture();
                var period = Fixture.Short();
                f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns("DueDate Days");
                var r = f.Subject.PeriodTypeToLocalizedString(period, PeriodType.Days, f.Culture);

                Assert.Equal(period + " DueDate Days", r);
            }

            [Theory]
            [InlineData(PeriodType.NotSet, "")]
            [InlineData(PeriodType.UserEntered, "User entered")]
            [InlineData(PeriodType.StandingInstruction_Period1, "Period 1")]
            [InlineData(PeriodType.StandingInstruction_Period2, "Period 2")]
            [InlineData(PeriodType.StandingInstruction_Period3, "Period 3")]
            public void ShouldReturnPeriodStartsWithStandingInstructions(PeriodType periodType, string expected)
            {
                var f = new EventRulesHelperFixture();
                f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns(expected);
                var r = f.Subject.PeriodTypeToLocalizedString(Fixture.Short(), periodType, f.Culture);

                Assert.Equal(expected, r);
            }

            [Theory]
            [InlineData("D", "Day(s)")]
            [InlineData("W", "Week(s)")]
            [InlineData("Y", "Year(s)")]
            public void ShouldReturnPeriodTypeToLocalizedStringWithString(string periodType, string expected)
            {
                var f = new EventRulesHelperFixture();
                var period = Fixture.Short();
                f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns(expected);
                var r = f.Subject.PeriodTypeToLocalizedString(period, periodType, f.Culture);

                Assert.Equal(period + " " + expected, r);
            }

            [Theory]
            [InlineData(null, "")]
            [InlineData("", "")]
            [InlineData("E", "User entered")]
            [InlineData("1", "Period 1")]
            [InlineData("2", "Period 2")]
            [InlineData("3", "Period 3")]
            public void ShouldReturnPeriodStartsWithStandingInstructionsWithString(string periodType, string expected)
            {
                var f = new EventRulesHelperFixture();
                f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns(expected);
                var r = f.Subject.PeriodTypeToLocalizedString(Fixture.Short(), periodType, f.Culture);

                Assert.Equal(expected, r);
            }
        }

        public class DateTypeToLocalizedStringMethod : FactBase
        {
            [Theory]
            [InlineData((int)DateType.NotSet, "")]
            [InlineData(null, "")]
            [InlineData((int)DateType.EventDate, "event date")]
            [InlineData((int)DateType.DueDate, "due date")]
            public void ShouldReturnDateTypeToLocalizedString(int? date, string expected)
            {
                var f = new EventRulesHelperFixture();
                f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns(expected);
                var r = f.Subject.DateTypeToLocalizedString(date, f.Culture);

                Assert.Equal(expected, r);
            }
        }

        public class RelativeCycleToLocalizedStringMethod : FactBase
        {
            [Theory]
            [InlineData(null, "")]
            [InlineData((int)RelativeCycle.NotSet, "")]
            [InlineData((int)RelativeCycle.CurrentCycle, "current cycle")]
            [InlineData((int)RelativeCycle.FirstCycle, "first cycle")]
            public void ShouldReturnRelativeCycleToLocalizedString(int? cycle, string expected)
            {
                var f = new EventRulesHelperFixture();
                f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns(expected);
                var r = f.Subject.RelativeCycleToLocalizedString(cycle, f.Culture);

                Assert.Equal(expected, r);
            }
        }

        public class RatesCodeToLocalizedStringMethod : FactBase
        {
            [Theory]
            [InlineData(null, "")]
            [InlineData((int)RatesCode.NotSet, "")]
            [InlineData((int)RatesCode.RaiseCharge, "raise charge")]
            [InlineData((int)RatesCode.PayFee, "payee fee")]
            public void ShouldReturnRatesCodeToLocalizedString(int? cycle, string expected)
            {
                var f = new EventRulesHelperFixture();
                f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns(expected);
                var r = f.Subject.RatesCodeToLocalizedString(cycle, f.Culture);

                Assert.Equal(expected, r);
            }
        }

        public class StringToComparisonOperatorMethod : FactBase
        {
            [Theory]
            [InlineData(null, ComparisonOperator.NotSet)]
            [InlineData("", ComparisonOperator.NotSet)]
            [InlineData("=", ComparisonOperator.EqualTo)]
            [InlineData("<>", ComparisonOperator.NotEqualTo)]
            [InlineData(">", ComparisonOperator.GreaterThan)]
            [InlineData("EX", ComparisonOperator.Exists)]
            [InlineData("NE", ComparisonOperator.NotExists)]
            public void ShouldReturnRelativeCycleToLocalizedString(string op, ComparisonOperator expected)
            {
                var f = new EventRulesHelperFixture();
                var r = f.Subject.StringToComparisonOperator(op);

                Assert.Equal(expected, r);
            }
        }

        public class ComparisonOperatorToSymbolMethod : FactBase
        {
            [Theory]
            [InlineData(null, "")]
            [InlineData("", "")]
            [InlineData("=", "=")]
            [InlineData("<>", "<>")]
            [InlineData("EX", "Exists")]
            [InlineData("NE", "Not Exists")]
            public void ShouldReturnRelativeCycleToLocalizedString(string op, string expected)
            {
                var f = new EventRulesHelperFixture();
                f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns(expected);

                var r = f.Subject.ComparisonOperatorToSymbol(op, f.Culture);

                Assert.Equal(expected, r);
            }
        }
    }

    public class EventRulesHelperFixture : IFixture<EventRulesHelper>
    {
        public EventRulesHelperFixture()
        {
            Culture = new[] {"en"};
            StaticTranslator = Substitute.For<IStaticTranslator>();
            Subject = new EventRulesHelper(StaticTranslator);
        }

        public string[] Culture;

        public IStaticTranslator StaticTranslator { get; set; }
        public EventRulesHelper Subject { get; }
    }
}
