using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameMarginProfileConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameMarginProfileConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameMarginProfileConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            if (option.KeepConsolidatedName) return;

            await _dbContext.DeleteAsync(from nmp in _dbContext.Set<NameMarginProfile>()
                                         where nmp.NameId == @from.Id
                                         select nmp);
        }
    }
}