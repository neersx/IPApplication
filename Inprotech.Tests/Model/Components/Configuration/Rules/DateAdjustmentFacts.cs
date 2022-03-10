using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.Rules
{
    public class DateAdjustmentFacts
    {
        [Fact]
        public void SortsAdjustments()
        {
            var builder = new DateAdjustmentBuilder();
            var zero = builder.Build(null, null, null);
            var one = builder.Build(null, null, null, 1);
            var two = builder.Build(1, null, null);
            var three = builder.Build(1, 1, null);
            var four = builder.Build(null, 1, null);
            var five = builder.Build(null, 1, 1);
            var six = builder.Build(1, 1, 1);
            var seven = builder.Build(null, null, 1);

            var adjustments = new[] {six, one, seven, zero, three, four, two, five};

            var result = adjustments.SortForPickList().ToList();

            Assert.Equal(0, result.IndexOf(zero));
            Assert.Equal(1, result.IndexOf(one));
            Assert.Equal(2, result.IndexOf(two));
            Assert.Equal(3, result.IndexOf(three));
            Assert.Equal(4, result.IndexOf(four));
            Assert.Equal(5, result.IndexOf(five));
            Assert.Equal(6, result.IndexOf(six));
            Assert.Equal(7, result.IndexOf(seven));
        }

        [Fact]
        public void SortsByAdjustmentPeriod()
        {
            var builder = new DateAdjustmentBuilder();
            var zero = builder.Build();
            var one = builder.Build();
            var two = builder.Build();
            var three = builder.Build();
            var four = builder.Build();
            var five = builder.Build();
            var six = builder.Build();

            zero.AdjustAmount = 1;
            zero.PeriodType = "Y";

            one.AdjustAmount = 1;
            one.PeriodType = "M";

            two.AdjustAmount = 3;
            two.PeriodType = "W";
            three.AdjustAmount = 1;
            three.PeriodType = "W";

            four.AdjustAmount = 3;
            four.PeriodType = "D";
            five.AdjustAmount = -1;
            five.PeriodType = "D";
            six.AdjustAmount = -21;
            six.PeriodType = "D";

            var list = new[] {five, zero, four, two, three, one, six};
            var result = list.SortForPickList().ToList();

            Assert.Equal(0, result.IndexOf(zero));
            Assert.Equal(1, result.IndexOf(one));
            Assert.Equal(2, result.IndexOf(two));
            Assert.Equal(3, result.IndexOf(three));
            Assert.Equal(4, result.IndexOf(four));
            Assert.Equal(5, result.IndexOf(five));
            Assert.Equal(6, result.IndexOf(six));
        }
    }
}