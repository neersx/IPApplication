using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameAliasConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameAliasConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameAliasConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await _dbContext.UpdateAsync(from na in _dbContext.Set<NameAlias>()
                                         join na1 in _dbContext.Set<NameAlias>().Where(_ => _.NameId == to.Id)
                                             on new {na.Alias, na.AliasType, na.Country, na.PropertyType} equals new {na1.Alias, na1.AliasType, na1.Country, na1.PropertyType}
                                             into na1J
                                         from na1 in na1J.DefaultIfEmpty()
                                         where na.NameId == @from.Id && na1 == null
                                         select na,
                                         _ => new NameAlias {NameId = to.Id});
        }
    }
}