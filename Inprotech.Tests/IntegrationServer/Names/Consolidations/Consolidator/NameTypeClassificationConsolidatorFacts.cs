using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class NameTypeClassificationConsolidatorFacts : FactBase
    {
        public NameTypeClassificationConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldCopyNameTypeClassification()
        {
            const bool keepConsolidatedName = true;

            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);
            var subject = new NameTypeClassificationConsolidator(Db);

            var nameType = new NameType(Fixture.String(), Fixture.String()).In(Db);

            new NameTypeClassification(_from, nameType) {IsAllowed = 1}.In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameTypeClassification>().Where(_ => _.NameId == _to.Id && _.NameTypeId == nameType.NameTypeCode));
            Assert.Empty(Db.Set<NameTypeClassification>().Where(_ => _.NameId == _from.Id));
        }

        [Fact]
        public async Task ShouldNotCopyNameTypeClassificationIfAllowedClassificationExistsAndKeepClassification()
        {
            const bool keepConsolidatedName = true;

            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);
            var subject = new NameTypeClassificationConsolidator(Db);

            var nameType = new NameType(Fixture.String(), Fixture.String()).In(Db);

            new NameTypeClassification(_from, nameType) {IsAllowed = 1}.In(Db);
            new NameTypeClassification(_to, nameType).In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameTypeClassification>().Where(_ => _.NameId == _to.Id && _.NameTypeId == nameType.NameTypeCode));
            Assert.Single(Db.Set<NameTypeClassification>().Where(_ => _.NameId == _from.Id && _.NameTypeId == nameType.NameTypeCode));
        }

        [Fact]
        public async Task ShouldNotCopyNameTypeClassificationIfAllowedClassificationExistsAndDeleteClassification()
        {
            const bool keepConsolidatedName = false;

            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);
            var subject = new NameTypeClassificationConsolidator(Db);

            var nameType = new NameType(Fixture.String(), Fixture.String()).In(Db);

            new NameTypeClassification(_from, nameType) { IsAllowed = 1 }.In(Db);
            new NameTypeClassification(_to, nameType).In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameTypeClassification>().Where(_ => _.NameId == _to.Id && _.NameTypeId == nameType.NameTypeCode));
            Assert.Empty(Db.Set<NameTypeClassification>().Where(_ => _.NameId == _from.Id && _.NameTypeId == nameType.NameTypeCode));
        }
    }
}