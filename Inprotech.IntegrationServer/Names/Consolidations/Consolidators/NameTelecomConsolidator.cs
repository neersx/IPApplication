using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameTelecomConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameTelecomConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameTelecomConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            if (!option.KeepTelecomHistory) return;

            await _dbContext.UpdateAsync(from nt in _dbContext.Set<NameTelecom>()
                                         join nt1 in _dbContext.Set<NameTelecom>().Where(_ => _.NameId == to.Id)
                                             on nt.TeleCode equals nt1.TeleCode into nt1J
                                         from nt1 in nt1J.DefaultIfEmpty()
                                         where nt.NameId == @from.Id && nt1 == null
                                         select nt,
                                         _ => new NameTelecom {NameId = to.Id});
        }
    }
}