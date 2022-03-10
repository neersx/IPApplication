using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class OrganisationConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public OrganisationConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(OrganisationConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            if (option.KeepConsolidatedName) return;

            await _dbContext.DeleteAsync(from o in _dbContext.Set<Organisation>()
                                         where o.Id == @from.Id
                                         select o);
        }
    }
}