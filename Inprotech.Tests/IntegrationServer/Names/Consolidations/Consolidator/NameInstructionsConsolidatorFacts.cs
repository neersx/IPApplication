using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class NameInstructionsConsolidatorFacts : FactBase
    {
        readonly Name _from;
        readonly Name _to;

        public NameInstructionsConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        [Theory]
        [InlineData(true, 3)]
        [InlineData(false, 0)]
        public async Task ShouldConsolidateUniqueNameInstruction(bool keepConsolidatedName, int numberOfFromNameRetained)
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            new NameInstructionBuilder {Id = _from.Id, Sequence = 1}.Build().In(Db);
            new NameInstructionBuilder {Id = _from.Id, Sequence = 2}.Build().In(Db);
            new NameInstructionBuilder {Id = _from.Id, Sequence = 3}.Build().In(Db);

            var subject = new NameInstructionsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Equal(numberOfFromNameRetained, Db.Set<NameInstruction>().Count(_ => _.Id == _from.Id));
            Assert.Equal(3, Db.Set<NameInstruction>().Count(_ => _.Id == _to.Id));
        }

        [Theory]
        [InlineData(true, false, false, false)]
        [InlineData(false, true, false, false)]
        [InlineData(false, false, true, false)]
        [InlineData(false, false, false, true)]
        [InlineData(true, true, false, false)]
        [InlineData(true, false, true, false)]
        [InlineData(true, false, false, true)]
        [InlineData(true, true, true, false)]
        [InlineData(true, true, false, true)]
        [InlineData(true, true, true, true)]
        public async Task ShouldNotConsolidateInstructionsWithSameCharacteristics
        (bool nullRestrictedToName,
         bool nullCaseId,
         bool nullCountryCode,
         bool nullPropertyType)
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), false);

            var fromInstruction = new NameInstructionBuilder {Id = _from.Id}.Build().In(Db);
            var toInstruction = new NameInstructionBuilder {Id = _to.Id}.Build().In(Db);

            fromInstruction.RestrictedToName = nullRestrictedToName ? toInstruction.RestrictedToName = null : toInstruction.RestrictedToName;
            fromInstruction.CaseId = nullCaseId ? toInstruction.CaseId = null : toInstruction.CaseId;
            fromInstruction.CountryCode = nullCountryCode ? toInstruction.CountryCode = null : toInstruction.CountryCode;
            fromInstruction.PropertyType = nullPropertyType ? toInstruction.PropertyType = null : toInstruction.PropertyType;

            var subject = new NameInstructionsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameInstruction>().Where(_ => _.Id == _to.Id));
        }
    }
}