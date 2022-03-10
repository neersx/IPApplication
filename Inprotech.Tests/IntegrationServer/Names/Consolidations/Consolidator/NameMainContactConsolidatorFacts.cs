using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class NameMainContactConsolidatorFacts : FactBase
    {
        public NameMainContactConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldUpdateAllMainContacts()
        {
            var consolidatedNamesMainContact = new Name().In(Db).Id;
            _to.MainContactId = consolidatedNamesMainContact;

            new Name {MainContactId = _from.Id}.In(Db);
            new Name {MainContactId = _from.Id}.In(Db);
            new Name {MainContactId = _from.Id}.In(Db);

            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var subject = new NameMainContactConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<Name>().Where(_ => _.MainContactId == _from.Id));
            Assert.Equal(4, Db.Set<Name>().Count(_ => _.MainContactId == consolidatedNamesMainContact));
        }
    }
}