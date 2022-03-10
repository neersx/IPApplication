using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class FeesCalculationsConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public FeesCalculationsConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(FeesCalculationsConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await DeleteOrUpdateAgent(to, from);

            await DeleteOrUpdateDebtor(to, from);

            await DeleteOrUpdateInstructor(to, from);

            await DeleteOrUpdateOwner(to, from);

            await UpdateDisbursementEmployee(to, from);

            await UpdateServiceEmployee(to, from);
        }

        async Task UpdateServiceEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from f in _dbContext.Set<FeesCalculation>()
                                         where f.ServiceEmployeeId == @from.Id
                                         select f,
                                         _ => new FeesCalculation { ServiceEmployeeId = to.Id });
        }

        async Task UpdateDisbursementEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from f in _dbContext.Set<FeesCalculation>()
                                         where f.DisbursementEmployeeId == @from.Id
                                         select f,
                                         _ => new FeesCalculation { DisbursementEmployeeId = to.Id });
        }

        async Task DeleteOrUpdateOwner(Name to, Name from)
        {
            var feeCalcsForOwner = from f1 in _dbContext.Set<FeesCalculation>()
                                   join f2 in _dbContext.Set<FeesCalculation>()
                                       on new
                                       {
                                           f1.CriteriaId,
                                           f1.DebtorType,
                                           f1.AgentId,
                                           f1.DebtorId,
                                           f1.CycleNumber,
                                           f1.ValidFromDate,
                                           OwnerId = (int?)to.Id,
                                           f1.InstructorId,
                                           f1.FromEventId
                                       }
                                        equals new
                                       {
                                           f2.CriteriaId,
                                           f2.DebtorType,
                                           f2.AgentId,
                                           f2.DebtorId,
                                           f2.CycleNumber,
                                           f2.ValidFromDate,
                                           f2.OwnerId,
                                           f2.InstructorId,
                                           f2.FromEventId
                                       }
                                   where f1.OwnerId == @from.Id
                                   select f1;

            if (feeCalcsForOwner.Any())
            {
                await _dbContext.DeleteAsync(feeCalcsForOwner);
            }

            await _dbContext.UpdateAsync(from f in _dbContext.Set<FeesCalculation>()
                                         where f.OwnerId == @from.Id
                                         select f,
                                         _ => new FeesCalculation { OwnerId = to.Id });

        }

        async Task DeleteOrUpdateInstructor(Name to, Name from)
        {
            var feeCalcsForInstructor = from f1 in _dbContext.Set<FeesCalculation>()
                                        join f2 in _dbContext.Set<FeesCalculation>()
                                            on new
                                            {
                                                f1.CriteriaId,
                                                f1.DebtorType,
                                                f1.AgentId,
                                                f1.DebtorId,
                                                f1.CycleNumber,
                                                f1.ValidFromDate,
                                                f1.OwnerId,
                                                InstructorId = (int?)to.Id,
                                                f1.FromEventId
                                            }
                                            equals new
                                            {
                                                f2.CriteriaId,
                                                f2.DebtorType,
                                                f2.AgentId,
                                                f2.DebtorId,
                                                f2.CycleNumber,
                                                f2.ValidFromDate,
                                                f2.OwnerId,
                                                f2.InstructorId,
                                                f2.FromEventId
                                            }
                                        where f1.InstructorId == @from.Id
                                        select f1;

            if (feeCalcsForInstructor.Any())
            {
                await _dbContext.DeleteAsync(feeCalcsForInstructor);
            }

            await _dbContext.UpdateAsync(from f in _dbContext.Set<FeesCalculation>()
                                         where f.InstructorId == @from.Id
                                         select f,
                                         _ => new FeesCalculation { InstructorId = to.Id });

        }

        async Task DeleteOrUpdateDebtor(Name to, Name from)
        {
            var feeCalcsForDebtor = from f1 in _dbContext.Set<FeesCalculation>()
                                    join f2 in _dbContext.Set<FeesCalculation>()
                                        on new
                                        {
                                            f1.CriteriaId,
                                            f1.DebtorType,
                                            f1.AgentId,
                                            DebtorId = (int?)to.Id,
                                            f1.CycleNumber,
                                            f1.ValidFromDate,
                                            f1.OwnerId,
                                            f1.InstructorId,
                                            f1.FromEventId
                                        }
                                        equals new
                                        {
                                            f2.CriteriaId,
                                            f2.DebtorType,
                                            f2.AgentId,
                                            f2.DebtorId,
                                            f2.CycleNumber,
                                            f2.ValidFromDate,
                                            f2.OwnerId,
                                            f2.InstructorId,
                                            f2.FromEventId
                                        }
                                    where f1.DebtorId == @from.Id
                                    select f1;

            if (feeCalcsForDebtor.Any())
            {
                await _dbContext.DeleteAsync(feeCalcsForDebtor);
            }

            await _dbContext.UpdateAsync(from f in _dbContext.Set<FeesCalculation>()
                                         where f.DebtorId == @from.Id
                                         select f,
                                         _ => new FeesCalculation { DebtorId = to.Id });

        }

        async Task DeleteOrUpdateAgent(Name to, Name from)
        {
            var feeCalcsForAgent = from f1 in _dbContext.Set<FeesCalculation>()
                                   join f2 in _dbContext.Set<FeesCalculation>()
                                       on new
                                       {
                                           f1.CriteriaId,
                                           f1.DebtorType,
                                           AgentId = (int?)to.Id,
                                           f1.DebtorId,
                                           f1.CycleNumber,
                                           f1.ValidFromDate,
                                           f1.OwnerId,
                                           f1.InstructorId,
                                           f1.FromEventId
                                       }
                                        equals new
                                       {
                                           f2.CriteriaId,
                                           f2.DebtorType,
                                           f2.AgentId,
                                           f2.DebtorId,
                                           f2.CycleNumber,
                                           f2.ValidFromDate,
                                           f2.OwnerId,
                                           f2.InstructorId,
                                           f2.FromEventId
                                       }
                                   where f1.AgentId == @from.Id
                                   select f1;

            if (feeCalcsForAgent.Any())
            {
                await _dbContext.DeleteAsync(feeCalcsForAgent);
            }

            await _dbContext.UpdateAsync(from f in _dbContext.Set<FeesCalculation>()
                                         where f.AgentId == @from.Id
                                         select f,
                                         _ => new FeesCalculation { AgentId = to.Id });

        }
    }
}