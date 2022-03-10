using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class ClientDetailsConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public ClientDetailsConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(ClientDetailsConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            if (!_dbContext.Set<ClientDetail>().Any(_ => _.Id == from.Id))
            {
                return;
            }

            await UpdateIpName(to, from);

            await DeleteExistingIpName(from, option);

            await EnsureClientName(to);
        }

        async Task EnsureClientName(Name to)
        {
            if ((to.UsedAs & NameUsedAs.Client) != NameUsedAs.Client)
            {
                to.UsedAs |= NameUsedAs.Client;

                await _dbContext.SaveChangesAsync();
            }
        }

        async Task DeleteExistingIpName(Name from, ConsolidationOption option)
        {
            if (option.KeepConsolidatedName) return;

            await _dbContext.DeleteAsync(_dbContext.Set<ClientDetail>().Where(_ => _.Id == from.Id));
        }

        async Task UpdateIpName(Name to, Name from)
        {
            if (_dbContext.Set<ClientDetail>().Any(_ => _.Id == to.Id)) return;

            await _dbContext.UpdateAsync(from cd in _dbContext.Set<ClientDetail>()
                                         where cd.Id == @from.Id
                                         select cd,
                                         _ => new ClientDetail {Id = to.Id});
        }
    }
}