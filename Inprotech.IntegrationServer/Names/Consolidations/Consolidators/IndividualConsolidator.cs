using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class IndividualConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public IndividualConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(INameConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await CopyIndividualDetails(to, from);

            await ChangeAssociatedNameParent(to, from);

            await DeleteIndividual(from, option.KeepConsolidatedName);
        }

        async Task CopyIndividualDetails(Name to, Name from)
        {
            var individuals = await _dbContext.Set<Individual>().Where(_ => _.NameId == from.Id || _.NameId == to.Id)
                                              .ToDictionaryAsync(k => k.NameId, v => v);

            if (individuals.ContainsKey(from.Id) && !individuals.ContainsKey(to.Id))
            {
                _dbContext.Set<Individual>().Add(new Individual(to.Id)
                {
                    Gender = individuals[from.Id].Gender,
                    FormalSalutation = individuals[from.Id].FormalSalutation,
                    CasualSalutation = individuals[from.Id].CasualSalutation
                });

                await _dbContext.SaveChangesAsync();
            }
        }

        async Task ChangeAssociatedNameParent(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from an in _dbContext.Set<AssociatedName>()
                                         where an.ContactId == @from.Id
                                         select an,
                                         name => new AssociatedName {ContactId = to.Id});
        }

        async Task DeleteIndividual(Name from, bool shouldKeepConsolidatedName)
        {
            if (shouldKeepConsolidatedName) return;

            await _dbContext.DeleteAsync(_dbContext.Set<Individual>().Where(_ => _.NameId == @from.Id));
        }
    }
}