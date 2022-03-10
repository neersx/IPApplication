using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameImageConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameImageConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameImageConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await _dbContext.UpdateAsync(from ni in _dbContext.Set<NameImage>()
                                         join ni1 in _dbContext.Set<NameImage>().Where(_ => _.Id == to.Id)
                                             on ni.ImageId equals ni1.ImageId into ni1J
                                         from ni1 in ni1J.DefaultIfEmpty()
                                         where ni.Id == @from.Id && ni1 == null
                                         select ni,
                                         _ => new NameImage {Id = to.Id});
        }
    }
}