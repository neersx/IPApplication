using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.Rules
{
    public interface IDateRuleValidator
    {
        IEnumerable<DateRuleViolation> Validate(
            int caseId,
            int criteriaId,
            int eventId,
            DateTime dateEntered,
            short cycle,
            DateLogicValidationType validationType);
    }

    public class ExternalDateRuleValidator : IDateRuleValidator
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public ExternalDateRuleValidator(IDbContext dbContext, ISecurityContext securityContext)
        {
            if(dbContext == null) throw new ArgumentNullException("dbContext");
            if(securityContext == null) throw new ArgumentNullException("securityContext");

            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public IEnumerable<DateRuleViolation> Validate(
            int caseId,
            int criteriaId,
            int eventId,
            DateTime dateEntered,
            short cycle,
            DateLogicValidationType validationType)
        {
            var sqlCommand = _dbContext.CreateStoredProcedureCommand("cs_GetCompareEventDates");
            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               new SqlParameter("@pnRowCount", null),
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                               new SqlParameter("@psCulture", null),
                                               new SqlParameter("@psGlobalTempTable", null),
                                               new SqlParameter("@pnCaseId", caseId),
                                               new SqlParameter("@pnEventNo", eventId),
                                               new SqlParameter("@pnCycle", cycle),
                                               new SqlParameter("@pnCriteriaNo", criteriaId),
                                               new SqlParameter("@pnEventType", (int)validationType),
                                               new SqlParameter("@pdEnteredDate", dateEntered),
                                               new SqlParameter("@pbCalledFromCentura", false)
                                           });

            var result = new List<DateRuleViolation>();

            using(IDataReader reader = sqlCommand.ExecuteReader())
            {
                reader.Read();
                if(reader.NextResult())
                {
                    while(reader.Read())
                    {
                        var detail = new DateRuleViolation
                                     {
                                         DateToCompare = (DateTime)reader["DateToCompare"],
                                         ComparisonEvent = reader["Comparisonevent"] as string,
                                         ComparisonDate = (DateTime)reader["ComparisonDate"],
                                         IsInvalid = Convert.ToInt32(reader["DisplayErrorFlag"]) == 1,
                                         Message = reader["ErrorMessage"] as string,
                                     };
                        result.Add(detail);
                    }
                }

                return result;
            }
        }
    }
}