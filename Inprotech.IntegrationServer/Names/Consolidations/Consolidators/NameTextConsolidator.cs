using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameTextConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameTextConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameTextConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await _dbContext.UpdateAsync(from nt in _dbContext.Set<NameText>()
                                         join nt1 in _dbContext.Set<NameText>().Where(_ => _.Id == to.Id)
                                             on nt.TextType equals nt1.TextType into nt1J
                                         from nt1 in nt1J.DefaultIfEmpty()
                                         where nt.Id == @from.Id && nt1 == null
                                         select nt,
                                         _ => new NameText {Id = to.Id});
        }
    }
}