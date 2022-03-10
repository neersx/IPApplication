using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameLanguageConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameLanguageConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameLanguageConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            if (option.KeepConsolidatedName) return;

            await _dbContext.DeleteAsync(from nl in _dbContext.Set<NameLanguage>()
                                         where nl.NameId == @from.Id
                                         select nl);
        }
    }
}