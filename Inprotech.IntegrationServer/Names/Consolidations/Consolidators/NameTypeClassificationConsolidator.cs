using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameTypeClassificationConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameTypeClassificationConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameTypeClassificationConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await UpdateNameTypeClassifications(to, from);

            await DeleteNameTypeClassifications(from, option);
        }

        async Task UpdateNameTypeClassifications(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from nt in _dbContext.Set<NameTypeClassification>()
                                         join nt1 in _dbContext.Set<NameTypeClassification>().Where(_ => _.NameId == to.Id)
                                             on nt.NameTypeId equals nt1.NameTypeId into nt1J
                                         from nt1 in nt1J.DefaultIfEmpty()
                                         where nt.NameId == @from.Id && nt.IsAllowed == 1 && nt1 == null
                                         select nt,
                                         _ => new NameTypeClassification
                                         {
                                             NameId = to.Id
                                         });
        }

        async Task DeleteNameTypeClassifications(Name from, ConsolidationOption option)
        {
            if (option.KeepConsolidatedName) return;

            await _dbContext.DeleteAsync(from nt in _dbContext.Set<NameTypeClassification>()
                                         where nt.NameId == @from.Id
                                         select nt);
        }
    }
}