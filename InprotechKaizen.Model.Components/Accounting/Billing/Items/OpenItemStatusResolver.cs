using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public interface IOpenItemStatusResolver
    {
        Task<TransactionStatus?> Resolve(int? itemEntityId, int? itemTransactionId);
    }

    public class OpenItemStatusResolver : IOpenItemStatusResolver
    {
        readonly IDbContext _dbContext;

        public OpenItemStatusResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<TransactionStatus?> Resolve(int? itemEntityId, int? itemTransactionId)
        {
            if (itemEntityId == null || itemTransactionId == null) return null;

            var status = await _dbContext.Set<OpenItem>()
                                         .Where(_ => _.ItemEntityId == itemEntityId && _.ItemTransactionId == itemTransactionId)
                                         .Select(_ => (short?) _.Status)
                                         .FirstOrDefaultAsync();

            return status == null
                ? null
                : (TransactionStatus) (short) status;
        }
    }
}