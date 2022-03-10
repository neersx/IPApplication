using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class FeesCalculationsConsolidatorFacts : FactBase
    {
        public FeesCalculationsConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldConsolidateFeeCalculationsUsingTheSameAgent()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            new FeesCalculationBuilder {AgentId = _from.Id}.Build().In(Db);

            var subject = new FeesCalculationsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<FeesCalculation>().Where(_ => _.AgentId == _from.Id));

            Assert.Single(Db.Set<FeesCalculation>().Where(_ => _.AgentId == _to.Id));
        }

        [Fact]
        public async Task ShouldConsolidateFeeCalculationsUsingTheSameDebtor()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            new FeesCalculationBuilder {DebtorId = _from.Id}.Build().In(Db);

            var subject = new FeesCalculationsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<FeesCalculation>().Where(_ => _.DebtorId == _from.Id));

            Assert.Single(Db.Set<FeesCalculation>().Where(_ => _.DebtorId == _to.Id));
        }

        [Fact]
        public async Task ShouldConsolidateFeeCalculationsUsingTheSameInstructor()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            new FeesCalculationBuilder {InstructorId = _from.Id}.Build().In(Db);

            var subject = new FeesCalculationsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<FeesCalculation>().Where(_ => _.InstructorId == _from.Id));

            Assert.Single(Db.Set<FeesCalculation>().Where(_ => _.InstructorId == _to.Id));
        }

        [Fact]
        public async Task ShouldConsolidateFeeCalculationsUsingTheSameOwner()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            new FeesCalculationBuilder {OwnerId = _from.Id}.Build().In(Db);

            var subject = new FeesCalculationsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<FeesCalculation>().Where(_ => _.OwnerId == _from.Id));

            Assert.Single(Db.Set<FeesCalculation>().Where(_ => _.OwnerId == _to.Id));
        }

        [Fact]
        public async Task ShouldNotConsolidateSimilarFeeCalculationsIfExistsForTheSameAgent()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var f = new FeesCalculationBuilder {AgentId = _from.Id}.Build().In(Db);
            var t = new FeesCalculationBuilder {AgentId = _to.Id}.Build().In(Db);

            f.CriteriaId = t.CriteriaId;
            f.DebtorType = t.DebtorType;
            f.DebtorId = t.DebtorId;
            f.CycleNumber = t.CycleNumber;
            f.ValidFromDate = t.ValidFromDate;
            f.OwnerId = t.OwnerId;
            f.InstructorId = t.InstructorId;
            f.FromEventId = t.FromEventId;

            var subject = new FeesCalculationsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<FeesCalculation>().Where(_ => _.AgentId == _from.Id));

            Assert.Single(Db.Set<FeesCalculation>().Where(_ => _.AgentId == _to.Id));
            // any attributes will not be the same.
            Assert.NotEqual(f.WriteUpReason, t.WriteUpReason);
        }

        [Fact]
        public async Task ShouldNotConsolidateSimilarFeeCalculationsIfExistsForTheSameDebtor()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var f = new FeesCalculationBuilder {DebtorId = _from.Id}.Build().In(Db);
            var t = new FeesCalculationBuilder {DebtorId = _to.Id}.Build().In(Db);

            f.CriteriaId = t.CriteriaId;
            f.DebtorType = t.DebtorType;
            f.AgentId = t.AgentId;
            f.CycleNumber = t.CycleNumber;
            f.ValidFromDate = t.ValidFromDate;
            f.OwnerId = t.OwnerId;
            f.InstructorId = t.InstructorId;
            f.FromEventId = t.FromEventId;

            var subject = new FeesCalculationsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<FeesCalculation>().Where(_ => _.DebtorId == _from.Id));

            Assert.Single(Db.Set<FeesCalculation>().Where(_ => _.DebtorId == _to.Id));
            // any attributes will not be the same.
            Assert.NotEqual(f.WriteUpReason, t.WriteUpReason);
        }

        [Fact]
        public async Task ShouldNotConsolidateSimilarFeeCalculationsIfExistsForTheSameInstructor()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var f = new FeesCalculationBuilder {InstructorId = _from.Id}.Build().In(Db);
            var t = new FeesCalculationBuilder {InstructorId = _to.Id}.Build().In(Db);

            f.CriteriaId = t.CriteriaId;
            f.DebtorType = t.DebtorType;
            f.DebtorId = t.DebtorId;
            f.CycleNumber = t.CycleNumber;
            f.ValidFromDate = t.ValidFromDate;
            f.OwnerId = t.OwnerId;
            f.AgentId = t.AgentId;
            f.FromEventId = t.FromEventId;

            var subject = new FeesCalculationsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<FeesCalculation>().Where(_ => _.InstructorId == _from.Id));

            Assert.Single(Db.Set<FeesCalculation>().Where(_ => _.InstructorId == _to.Id));
            // any attributes will not be the same.
            Assert.NotEqual(f.WriteUpReason, t.WriteUpReason);
        }

        [Fact]
        public async Task ShouldNotConsolidateSimilarFeeCalculationsIfExistsForTheSameOwner()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var f = new FeesCalculationBuilder {OwnerId = _from.Id}.Build().In(Db);
            var t = new FeesCalculationBuilder {OwnerId = _to.Id}.Build().In(Db);

            f.CriteriaId = t.CriteriaId;
            f.DebtorType = t.DebtorType;
            f.DebtorId = t.DebtorId;
            f.CycleNumber = t.CycleNumber;
            f.ValidFromDate = t.ValidFromDate;
            f.AgentId = t.AgentId;
            f.InstructorId = t.InstructorId;
            f.FromEventId = t.FromEventId;

            var subject = new FeesCalculationsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<FeesCalculation>().Where(_ => _.OwnerId == _from.Id));

            Assert.Single(Db.Set<FeesCalculation>().Where(_ => _.OwnerId == _to.Id));
            // any attributes will not be the same.
            Assert.NotEqual(f.WriteUpReason, t.WriteUpReason);
        }

        [Fact]
        public async Task ShouldUpdateDisbursementEmployeeReferences()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            new FeesCalculationBuilder {DisbursementEmployeeId = _from.Id}.Build().In(Db);
            new FeesCalculationBuilder {DisbursementEmployeeId = _from.Id}.Build().In(Db);
            new FeesCalculationBuilder {DisbursementEmployeeId = _from.Id}.Build().In(Db);

            var subject = new FeesCalculationsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<FeesCalculation>().Where(_ => _.DisbursementEmployeeId == _from.Id));

            Assert.Equal(3, Db.Set<FeesCalculation>().Count(_ => _.DisbursementEmployeeId == _to.Id));
        }

        [Fact]
        public async Task ShouldUpdateServiceEmployeeReferences()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            new FeesCalculationBuilder {ServiceEmployeeId = _from.Id}.Build().In(Db);
            new FeesCalculationBuilder {ServiceEmployeeId = _from.Id}.Build().In(Db);
            new FeesCalculationBuilder {ServiceEmployeeId = _from.Id}.Build().In(Db);

            var subject = new FeesCalculationsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<FeesCalculation>().Where(_ => _.ServiceEmployeeId == _from.Id));

            Assert.Equal(3, Db.Set<FeesCalculation>().Count(_ => _.ServiceEmployeeId == _to.Id));
        }
    }
}