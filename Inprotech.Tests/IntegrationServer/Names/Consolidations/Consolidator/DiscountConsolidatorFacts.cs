using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class DiscountConsolidatorFacts : FactBase
    {
        public DiscountConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
            _other = new Name().In(Db);
        }

        readonly Name _from;
        readonly Name _to;
        readonly Name _other;

        [Theory]
        [InlineData(true, 3)]
        [InlineData(false, 0)]
        public async Task ShouldConsolidateUniqueDiscount(bool keepConsolidatedName, int numberOfFromNameRetained)
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            new DiscountBuilder {NameId = _from.Id, Sequence = 1}.Build().In(Db);
            new DiscountBuilder {NameId = _from.Id, Sequence = 2}.Build().In(Db);
            new DiscountBuilder {NameId = _from.Id, Sequence = 3}.Build().In(Db);

            var subject = new DiscountConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Equal(numberOfFromNameRetained, Db.Set<Discount>().Count(_ => _.NameId == _from.Id));
            Assert.Equal(3, Db.Set<Discount>().Count(_ => _.NameId == _to.Id));
        }

        [Theory]
        [InlineData(true, false, false, false, false, false, false, false, false, false)]
        [InlineData(false, true, false, false, false, false, false, false, false, false)]
        [InlineData(false, false, true, false, false, false, false, false, false, false)]
        [InlineData(false, false, false, true, false, false, false, false, false, false)]
        [InlineData(false, false, false, false, true, false, false, false, false, false)]
        [InlineData(false, false, false, false, false, true, false, false, false, false)]
        [InlineData(false, false, false, false, false, false, true, false, false, false)]
        [InlineData(false, false, false, false, false, false, false, true, false, false)]
        [InlineData(false, false, false, false, false, false, false, false, true, false)]
        [InlineData(false, false, false, false, false, false, false, false, false, true)]
        [InlineData(true, true, false, false, false, false, false, false, false, false)]
        [InlineData(true, false, false, false, false, true, false, false, false, false)]
        [InlineData(true, false, false, false, false, false, true, false, false, false)]
        [InlineData(true, false, false, false, false, false, false, true, false, false)]
        [InlineData(true, false, false, false, false, false, false, false, true, false)]
        [InlineData(true, false, false, false, false, false, false, false, false, true)]
        [InlineData(true, true, true, false, false, false, false, false, false, false)]
        [InlineData(true, true, false, true, false, false, false, false, false, false)]
        [InlineData(true, true, false, false, true, false, false, false, false, false)]
        [InlineData(true, true, false, false, false, true, false, false, false, false)]
        [InlineData(true, true, false, false, false, false, false, false, true, false)]
        [InlineData(true, true, false, false, false, false, false, false, false, true)]
        [InlineData(true, true, true, true, false, false, false, false, false, false)]
        public async Task ShouldNotConsolidateInstructionsWithSameCharacteristics
        (bool nullPropertyTypeId,
         bool nullActionId,
         bool nullWipCategory,
         bool nullWipTypeId,
         bool nullEmployeeId,
         bool nullProductCode,
         bool nullCaseOwnerId,
         bool nullWipCode,
         bool nullCaseTypeId,
         bool nullCountryId)
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), false);

            var fromDiscount = new DiscountBuilder {NameId = _from.Id}.Build().In(Db);
            var toDiscount = new DiscountBuilder {NameId = _to.Id}.Build().In(Db);

            fromDiscount.PropertyTypeId = nullPropertyTypeId ? toDiscount.PropertyTypeId = null : toDiscount.PropertyTypeId;
            fromDiscount.ActionId = nullActionId ? toDiscount.ActionId = null : toDiscount.ActionId;
            fromDiscount.WipCategory = nullWipCategory ? toDiscount.WipCategory = null : toDiscount.WipCategory;
            fromDiscount.WipTypeId = nullWipTypeId ? toDiscount.WipTypeId = null : toDiscount.WipTypeId;
            fromDiscount.EmployeeId = nullEmployeeId ? toDiscount.EmployeeId = null : toDiscount.EmployeeId;
            fromDiscount.ProductCode = nullProductCode ? toDiscount.ProductCode = null : toDiscount.ProductCode;
            fromDiscount.CaseOwnerId = nullCaseOwnerId ? toDiscount.CaseOwnerId = null : toDiscount.CaseOwnerId;
            fromDiscount.WipCode = nullWipCode ? toDiscount.WipCode = null : toDiscount.WipCode;
            fromDiscount.CaseTypeId = nullCaseTypeId ? toDiscount.CaseTypeId = null : toDiscount.CaseTypeId;
            fromDiscount.CountryId = nullCountryId ? toDiscount.CountryId = null : toDiscount.CountryId;

            var subject = new DiscountConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<Discount>().Where(_ => _.NameId == _to.Id));
        }

        [Fact]
        public async Task ShouldConsolidateCaseOwnerInDiscount()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            new DiscountBuilder
            {
                NameId = _other.Id,
                Sequence = 1,
                CaseOwnerId = _from.Id
            }.Build().In(Db);

            var subject = new DiscountConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<Discount>().Where(_ => _.CaseOwnerId == _to.Id));
            Assert.Empty(Db.Set<Discount>().Where(_ => _.CaseOwnerId == _from.Id));
        }

        [Fact]
        public async Task ShouldConsolidateEmployeeInDiscount()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            new DiscountBuilder
            {
                NameId = _other.Id,
                Sequence = 1,
                EmployeeId = _from.Id
            }.Build().In(Db);

            var subject = new DiscountConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<Discount>().Where(_ => _.EmployeeId == _to.Id));
            Assert.Empty(Db.Set<Discount>().Where(_ => _.EmployeeId == _from.Id));
        }
    }
}