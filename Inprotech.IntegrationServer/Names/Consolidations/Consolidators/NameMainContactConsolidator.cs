using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameMainContactConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameMainContactConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameMainContactConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await _dbContext.UpdateAsync(from n in _dbContext.Set<Name>()
                                         where n.MainContactId == @from.Id
                                         select n,
                                         _ => new Name {MainContactId = to.MainContactId});
        }
    }
}