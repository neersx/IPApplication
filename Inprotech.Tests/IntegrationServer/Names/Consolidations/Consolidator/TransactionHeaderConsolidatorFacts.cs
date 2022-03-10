using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class TransactionHeaderConsolidatorFacts : FactBase
    {
        [Fact]
        public async Task ShouldConsolidateAllTransactionHeader()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var nameFrom = new Name().In(Db);
            var nameTo = new Name().In(Db);

            new TransactionHeader {StaffId = nameFrom.Id}.In(Db);
            new TransactionHeader {StaffId = nameFrom.Id}.In(Db);
            new TransactionHeader {StaffId = nameFrom.Id}.In(Db);

            var subject = new TransactionHeaderConsolidator(Db);

            await subject.Consolidate(nameTo, nameFrom, option);

            Assert.Empty(Db.Set<TransactionHeader>().Where(_ => _.StaffId == nameFrom.Id));
            Assert.Equal(3, Db.Set<TransactionHeader>().Count(_ => _.StaffId == nameTo.Id));
        }
    }
}