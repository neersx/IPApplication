using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameFilesInConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameFilesInConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameFilesInConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await _dbContext.UpdateAsync(from fi in _dbContext.Set<FilesIn>()
                                         join fi1 in _dbContext.Set<FilesIn>().Where(_ => _.NameId == to.Id)
                                             on fi.JurisdictionId equals fi1.JurisdictionId into fi1J
                                         from fi1 in fi1J.DefaultIfEmpty()
                                         where fi.NameId == @from.Id && fi1 == null
                                         select fi,
                                         _ => new FilesIn {NameId = to.Id});
        }
    }
}