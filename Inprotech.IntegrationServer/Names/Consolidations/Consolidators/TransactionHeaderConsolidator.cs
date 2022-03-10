using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class TransactionHeaderConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public TransactionHeaderConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(TransactionHeaderConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await _dbContext.UpdateAsync(from th in _dbContext.Set<TransactionHeader>()
                                         where th.StaffId == @from.Id
                                         select th,
                                         _ => new TransactionHeader
                                         {
                                             StaffId = to.Id
                                         });
        }
    }
}