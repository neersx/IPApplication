using System;
using System.Data;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases
{
    public class NextRenewalDatesResolver : INextRenewalDatesResolver
    {
        readonly IDbContext _dbContext;

        public NextRenewalDatesResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<RenewalDates> Resolve(int caseId, int? criteriaNo)
        {
            var result = new RenewalDates();

            if (criteriaNo.HasValue)
            {
                var exists = await (from n in _dbContext.Set<ValidEvent>()
                                    where n.EventId == (int) KnownEvents.NextRenewalDate && n.CriteriaId == criteriaNo
                                    select n).AnyAsync();

                if (exists)
                {
                    var renewalDates = await GetRenewalDates(caseId);
                    result.NextRenewalDate = renewalDates.NextRenewalDate;
                    result.CpaRenewalDate = renewalDates.CpaRenewalDate;
                }
            }

            result.AgeOfCase = await GetAgeOfCase(caseId, result.NextRenewalDate, result.CpaRenewalDate);

            return result;
        }

        public async Task<RenewalDates> Resolve(int caseId)
        {
            var result = new RenewalDates();

            var renewalDates = await GetRenewalDates(caseId);

            result.NextRenewalDate = renewalDates.NextRenewalDate;
            result.CpaRenewalDate = renewalDates.CpaRenewalDate;

            result.AgeOfCase = await GetAgeOfCase(caseId, result.NextRenewalDate);

            return result;
        }

        async Task<(DateTime? NextRenewalDate, DateTime? CpaRenewalDate)> GetRenewalDates(int caseId)
        {
            using (var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.GetNextRenewalDate))
            {
                command.Parameters.AddWithValue("pnCaseKey", caseId);

                var next = command.Parameters.Add(new SqlParameter("pdtNextRenewalDate", SqlDbType.DateTime)
                {
                    Direction = ParameterDirection.InputOutput
                });
                var cpa = command.Parameters.Add(new SqlParameter("pdtCPARenewalDate", SqlDbType.DateTime)
                {
                    Direction = ParameterDirection.InputOutput
                });

                await command.ExecuteNonQueryAsync();
                return (NextRenewalDate: next.Value == DBNull.Value ? null : (DateTime?) next.Value,
                    CpaRenewalDate: cpa.Value == DBNull.Value ? null : (DateTime?) cpa.Value);
            }
        }

        async Task<short?> GetAgeOfCase(int caseId, DateTime? nextRenewalDate, DateTime? cpaRenewalDate = null)
        {
            using (var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.GetAgeOfCase))
            {
                command.Parameters.AddWithValue("pnCaseId", caseId);
                command.Parameters.AddWithValue("pdtNextRenewalDate", nextRenewalDate);
                command.Parameters.AddWithValue("pdtCPARenewalDate", cpaRenewalDate);

                var age = command.Parameters.Add(new SqlParameter("pnAgeOfCase", SqlDbType.SmallInt)
                {
                    Direction = ParameterDirection.InputOutput,
                    Value = DBNull.Value
                });

                await command.ExecuteNonQueryAsync();

                return age.Value == DBNull.Value ? null : (short?) age.Value;
            }
        }
    }
}