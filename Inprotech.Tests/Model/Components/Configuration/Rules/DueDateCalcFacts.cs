using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.Rules
{
    public class DueDateCalcExtFacts : FactBase
    {
        [Fact]
        public void ReturnsCorrectRowType()
        {
            var dbContext = Db;

            var validEvent = new ValidEventBuilder().Build().In(Db);
            new DueDateCalc(validEvent, 0) {FromEventId = Fixture.Integer(), JurisdictionId = Fixture.String()}.In(Db);
            new DueDateCalc(validEvent, 1) {Comparison = "="}.In(Db);
            new DueDateCalc(validEvent, 2) {JurisdictionId = Fixture.String()}.In(Db);

            var dueDateCalc = dbContext.Set<DueDateCalc>().WhereDueDateCalc();
            var dateComparison = dbContext.Set<DueDateCalc>().WhereDateComparison();
            var designatedJurisdiction = dbContext.Set<DueDateCalc>().WhereDesignatedJurisdiction();

            Assert.Equal(0, dueDateCalc.Single().Sequence);
            Assert.Equal(1, dateComparison.Single().Sequence);
            Assert.Equal(2, designatedJurisdiction.Single().Sequence);
        }
    }

    public class HashKeyMethod
    {
        [Theory]
        [InlineData(1, "AA", 2, 3)]
        [InlineData(null, null, null, null)]
        [InlineData(null, null, 3, 2)]
        [InlineData(2, "X", null, null)]
        public void GeneratesConsistentHashKey(int? cycle, string jurisdictionCode, int? fromEventId, int? relativeCycle)
        {
            var dueDateCalc1 = new DueDateCalc {Cycle = (short?) cycle, JurisdictionId = jurisdictionCode, FromEventId = fromEventId, RelativeCycle = (short?) relativeCycle};
            var dueDateCalc2 = new DueDateCalc {Cycle = (short?) cycle, JurisdictionId = jurisdictionCode, FromEventId = fromEventId, RelativeCycle = (short?) relativeCycle};
            Assert.Equal(dueDateCalc1.HashKey(), dueDateCalc2.HashKey());

            var dueDateCalcDifferent1 = new DueDateCalc {Cycle = (short?) (cycle.GetValueOrDefault(0) + 1), JurisdictionId = jurisdictionCode, FromEventId = fromEventId, RelativeCycle = (short?) relativeCycle};
            var dueDateCalcDifferent2 = new DueDateCalc {Cycle = (short?) (cycle.GetValueOrDefault(0) + 1), JurisdictionId = jurisdictionCode + "X", FromEventId = fromEventId, RelativeCycle = (short?) relativeCycle};
            var dueDateCalcDifferent3 = new DueDateCalc {Cycle = (short?) cycle, JurisdictionId = jurisdictionCode, FromEventId = fromEventId.GetValueOrDefault() + 1, RelativeCycle = (short?) relativeCycle};
            var dueDateCalcDifferent4 = new DueDateCalc {Cycle = (short?) cycle, JurisdictionId = jurisdictionCode, FromEventId = fromEventId, RelativeCycle = (short?) (relativeCycle.GetValueOrDefault() + 1)};

            Assert.NotEqual(dueDateCalc1.HashKey(), dueDateCalcDifferent1.HashKey());
            Assert.NotEqual(dueDateCalc1.HashKey(), dueDateCalcDifferent2.HashKey());
            Assert.NotEqual(dueDateCalc1.HashKey(), dueDateCalcDifferent3.HashKey());
            Assert.NotEqual(dueDateCalc1.HashKey(), dueDateCalcDifferent4.HashKey());
        }

        [Fact]
        public void GeneratesConsistentHashKeyForDateComparison()
        {
            var baseDateComparison = new DueDateCalc();
            DataFiller.Fill(baseDateComparison);
            var dcSame = new DueDateCalc
            {
                Comparison = baseDateComparison.Comparison,
                FromEventId = baseDateComparison.FromEventId,
                RelativeCycle = baseDateComparison.RelativeCycle,
                EventDateFlag = baseDateComparison.EventDateFlag,
                CompareEventId = baseDateComparison.CompareEventId,
                CompareCycle = baseDateComparison.CompareCycle,
                CompareEventFlag = baseDateComparison.CompareEventFlag,
                CompareRelationshipId = baseDateComparison.CompareRelationshipId,
                CompareSystemDate = baseDateComparison.CompareSystemDate,
                CompareDate = baseDateComparison.CompareDate
            };

            var dc1 = new DueDateCalc().CopyFrom(baseDateComparison);
            var dc2 = new DueDateCalc().CopyFrom(baseDateComparison);
            var dc3 = new DueDateCalc().CopyFrom(baseDateComparison);
            var dc4 = new DueDateCalc().CopyFrom(baseDateComparison);
            var dc5 = new DueDateCalc().CopyFrom(baseDateComparison);
            var dc6 = new DueDateCalc().CopyFrom(baseDateComparison);
            var dc7 = new DueDateCalc().CopyFrom(baseDateComparison);
            var dc8 = new DueDateCalc().CopyFrom(baseDateComparison);
            var dc9 = new DueDateCalc().CopyFrom(baseDateComparison);
            var dc10 = new DueDateCalc().CopyFrom(baseDateComparison);
            dc1.Comparison = null;
            dc2.FromEventId = null;
            dc3.RelativeCycle = null;
            dc4.EventDateFlag = null;
            dc5.CompareEventId = null;
            dc6.CompareCycle = null;
            dc7.CompareEventFlag = null;
            dc8.CompareRelationshipId = null;
            dc9.CompareSystemDate = !baseDateComparison.CompareSystemDate.GetValueOrDefault();
            dc10.CompareDate = null;

            var baseHashKey = baseDateComparison.HashKey();
            Assert.Equal(dcSame.HashKey(), baseHashKey);
            Assert.NotEqual(dc1.HashKey(), baseHashKey);
            Assert.NotEqual(dc2.HashKey(), baseHashKey);
            Assert.NotEqual(dc3.HashKey(), baseHashKey);
            Assert.NotEqual(dc4.HashKey(), baseHashKey);
            Assert.NotEqual(dc5.HashKey(), baseHashKey);
            Assert.NotEqual(dc6.HashKey(), baseHashKey);
            Assert.NotEqual(dc7.HashKey(), baseHashKey);
            Assert.NotEqual(dc8.HashKey(), baseHashKey);
            Assert.NotEqual(dc9.HashKey(), baseHashKey);
            Assert.NotEqual(dc10.HashKey(), baseHashKey);
        }
    }

    public class InheritFromMethod
    {
        [Fact]
        public void CopiesPropertiesAndSetsInheritedFlag()
        {
            var subject = new DueDateCalc(new ValidEventBuilder().Build(), Fixture.Short());
            var from = new DueDateCalc(new ValidEventBuilder().Build(), Fixture.Short());

            DataFiller.Fill(from);
            from.IsInherited = false;

            subject.InheritRuleFrom(from);

            Assert.NotEqual(from.CriteriaId, subject.CriteriaId);
            Assert.NotEqual(from.EventId, subject.EventId);
            Assert.NotEqual(from.Sequence, subject.Sequence);
            Assert.NotEqual(from.Inherited, subject.Inherited);

            Assert.Equal(subject.Cycle, from.Cycle);
            Assert.Equal(subject.JurisdictionId, from.JurisdictionId);
            Assert.Equal(subject.FromEventId, from.FromEventId);
            Assert.Equal(subject.RelativeCycle, from.RelativeCycle);
            Assert.Equal(subject.Operator, from.Operator);
            Assert.Equal(subject.DeadlinePeriod, from.DeadlinePeriod);
            Assert.Equal(subject.PeriodType, from.PeriodType);
            Assert.Equal(subject.EventDateFlag, from.EventDateFlag);
            Assert.Equal(subject.Adjustment, from.Adjustment);
            Assert.Equal(subject.MustExist, from.MustExist);
            Assert.Equal(subject.Comparison, from.Comparison);
            Assert.Equal(subject.CompareEventId, from.CompareEventId);
            Assert.Equal(subject.Workday, from.Workday);
            Assert.Equal(subject.Message2Flag, from.Message2Flag);
            Assert.Equal(subject.SuppressReminders, from.SuppressReminders);
            Assert.Equal(subject.OverrideLetterId, from.OverrideLetterId);
            Assert.Equal(subject.CompareEventFlag, from.CompareEventFlag);
            Assert.Equal(subject.CompareCycle, from.CompareCycle);
            Assert.Equal(subject.CompareRelationshipId, from.CompareRelationshipId);
            Assert.Equal(subject.CompareDate, from.CompareDate);
            Assert.Equal(subject.CompareSystemDate, from.CompareSystemDate);
        }

        [Fact]
        public void SetsInheritedFlagToTrue()
        {
            var subject = new DueDateCalc(new ValidEventBuilder().Build(), Fixture.Short());
            var from = new DueDateCalc(new ValidEventBuilder().Build(), Fixture.Short());
            subject.InheritRuleFrom(from);

            Assert.True(subject.IsInherited);
        }
    }
}