using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class NameInstructionsConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public NameInstructionsConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(NameInstructionsConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await CopyNameInstructions(to, from);

            await UpdateRestrictedToName(to, from);

            await DeleteNameInstructionsByName(from, option.KeepConsolidatedName);

            await DeleteNameInstructionsByRestrictedToName(from, option.KeepConsolidatedName);
        }

        async Task CopyNameInstructions(Name to, Name from)
        {
            var maxNameInstructions = from d in _dbContext.Set<NameInstruction>().AsQueryable()
                                      group d by d.Id
                                      into g1
                                      select new
                                      {
                                          NameId = g1.Key,
                                          Sequence = g1.DefaultIfEmpty().Max(_ => (short?) _.Sequence) ?? 0
                                      };

            var nameInstructionsToCopy = await (from n in _dbContext.Set<NameInstruction>()
                                                join n1 in maxNameInstructions on new {NameId = to.Id} equals new {n1.NameId} into n1J
                                                from n1 in n1J.DefaultIfEmpty()
                                                join n2 in _dbContext.Set<NameInstruction>().Where(_ => _.Id == to.Id)
                                                    on new
                                                    {
                                                        n.RestrictedToName,
                                                        n.CaseId,
                                                        n.CountryCode,
                                                        n.PropertyType
                                                    }
                                                    equals new
                                                    {
                                                        n2.RestrictedToName,
                                                        n2.CaseId,
                                                        n2.CountryCode,
                                                        n2.PropertyType
                                                    }
                                                    into n2J
                                                from n2 in n2J.DefaultIfEmpty()
                                                where n.Id == @from.Id && n2 == null
                                                select new
                                                {
                                                    to.Id,
                                                    Sequence = (short) (n.Sequence + (n1 == null ? 0 : n1.Sequence) + 1),
                                                    n.RestrictedToName,
                                                    n.InstructionId,
                                                    n.CaseId,
                                                    n.CountryCode,
                                                    n.PropertyType,
                                                    n.Period1Amt,
                                                    n.Period1Type,
                                                    n.Period2Amt,
                                                    n.Period2Type,
                                                    n.Period3Amt,
                                                    n.Period3Type,
                                                    n.Adjustment,
                                                    n.AdjustDay,
                                                    n.AdjustStartMonth,
                                                    n.AdjustDayOfWeek,
                                                    n.AdjustToDate,
                                                    n.StandingInstructionText
                                                }).ToArrayAsync();

            foreach (var nameInstruction in nameInstructionsToCopy)
            {
                _dbContext.Set<NameInstruction>().Add(new NameInstruction
                {
                    Id = nameInstruction.Id,
                    Sequence = nameInstruction.Sequence,
                    RestrictedToName = nameInstruction.RestrictedToName,
                    InstructionId = nameInstruction.InstructionId,
                    CaseId = nameInstruction.CaseId,
                    CountryCode = nameInstruction.CountryCode,
                    PropertyType = nameInstruction.PropertyType,
                    Period1Amt = nameInstruction.Period1Amt,
                    Period1Type = nameInstruction.Period1Type,
                    Period2Amt = nameInstruction.Period2Amt,
                    Period2Type = nameInstruction.Period2Type,
                    Period3Amt = nameInstruction.Period3Amt,
                    Period3Type = nameInstruction.Period3Type,
                    Adjustment = nameInstruction.Adjustment,
                    AdjustDay = nameInstruction.AdjustDay,
                    AdjustStartMonth = nameInstruction.AdjustStartMonth,
                    AdjustDayOfWeek = nameInstruction.AdjustDayOfWeek,
                    AdjustToDate = nameInstruction.AdjustToDate,
                    StandingInstructionText = nameInstruction.StandingInstructionText
                });
            }

            await _dbContext.SaveChangesAsync();
        }

        async Task UpdateRestrictedToName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from d in _dbContext.Set<NameInstruction>()
                                         where d.RestrictedToName == @from.Id
                                         select d,
                                         _ => new NameInstruction {RestrictedToName = to.Id});
        }

        async Task DeleteNameInstructionsByName(Name from, bool shouldKeepConsolidatedName)
        {
            if (shouldKeepConsolidatedName) return;

            await _dbContext.DeleteAsync(from d in _dbContext.Set<NameInstruction>()
                                         where d.Id == @from.Id
                                         select d);
        }

        async Task DeleteNameInstructionsByRestrictedToName(Name from, bool shouldKeepConsolidatedName)
        {
            if (shouldKeepConsolidatedName) return;

            await _dbContext.DeleteAsync(from d in _dbContext.Set<NameInstruction>()
                                         where d.RestrictedToName == @from.Id
                                         select d);
        }
    }
}