using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameAddressConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameAddressConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameAddressConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            if (option.KeepAddressHistory ||
                await _dbContext.Set<CaseName>().AnyAsync(_ => _.NameId == from.Id && _.Address != null) ||
                await _dbContext.Set<NameAddressCpaClient>().AnyAsync(_ => _.NameId == from.Id))
            {
                await CopyNameAddress(to, from);

                await UpdateCpaClient(to, from);
            }
        }

        async Task CopyNameAddress(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from na in _dbContext.Set<NameAddress>()
                                         join na1 in _dbContext.Set<NameAddress>().Where(_ => _.NameId == to.Id)
                                             on new {na.AddressType, na.AddressId} equals new {na1.AddressType, na1.AddressId} into na1J
                                         from na1 in na1J.DefaultIfEmpty()
                                         where na.NameId == @from.Id && na1 == null
                                         select na,
                                         na => new NameAddress
                                         {
                                             NameId = to.Id,
                                             AddressType = na.AddressType,
                                             AddressStatus = na.AddressStatus,
                                             OwnedBy = na.OwnedBy,
                                             DateCeased = na.DateCeased
                                         });
        }

        async Task UpdateCpaClient(Name to, Name from)
        {
            await _dbContext.UpdateAsync(_dbContext.Set<NameAddressCpaClient>().Where(_ => _.NameId == from.Id),
                                         _ => new NameAddressCpaClient {NameId = to.Id});
        }
    }
}