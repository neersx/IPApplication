using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DataValidation
{

    public interface IExternalDataValidator
    {
        IEnumerable<ValidationResult> Validate(int? caseId, int? nameId, int transactionNo);
    }

    public class ExternalDataValidator : IExternalDataValidator
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public ExternalDataValidator(IDbContext dbContext, ISecurityContext securityContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (securityContext == null) throw new ArgumentNullException("securityContext");
            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public IEnumerable<ValidationResult> Validate(int? caseId, int? nameId, int transactionNo)
        {
            using (var sqlCommand = _dbContext.CreateStoredProcedureCommand("ip_DataValidation"))
            {
                sqlCommand.CommandTimeout = 0;
                sqlCommand.Parameters.AddRange(
                                               new[]
                                               {
                                                   new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                                   new SqlParameter("@psCulture", null),
                                                   new SqlParameter("@psFunctionalArea", caseId.HasValue ? "C" : "N"),
                                                   new SqlParameter("@pnCaseId", caseId),
                                                   new SqlParameter("@pnNameNo", nameId),
                                                   new SqlParameter("@pnTransactionNo", transactionNo)
                                               });

                using (IDataReader dr = sqlCommand.ExecuteReader())
                {
                    while (dr.Read())
                    {
                        var vr = new ValidationResult(dr["DisplayMessage"].ToString(), GetSeverity(dr))
                            .Named("SanityCheckResult")
                            .WithCorrelationId((int)dr["ValidationKey"])
                            .WithFunctionalArea(dr["FunctionalArea"].ToString() == "C" ? 0 : 1)
                            .WithValidationKey((int?)dr["ValidationKey"])
                            .WithIsWarning((bool?)dr["IsWarning"])
                            .WithCanOverride((bool)dr["CanOverride"]);
                        
                        if (!dr.IsDBNull(dr.GetOrdinal("CaseKey")))
                            vr = vr.WithCaseId((int)dr["CaseKey"]);
                        if (!dr.IsDBNull(dr.GetOrdinal("NameKey")))
                            vr = vr.WithNameId((int)dr["NameKey"]);
                        if (!dr.IsDBNull(dr.GetOrdinal("ProgramContext")))
                            vr = vr.WithProgramContext((int)dr["ProgramContext"]);
                        if (!dr.IsDBNull(dr.GetOrdinal("DisplayMessage")))
                            vr = vr.WithDisplayMessage(dr["DisplayMessage"].ToString());

                        yield return vr;
                    }
                }
            }
        }

        static Severity GetSeverity(IDataReader reader)
        {
            if ((bool?) reader["IsWarning"] ?? false)
                return Severity.Information;

            if ((bool)reader["CanOverride"] && !(bool)reader["IsWarning"])
                return Severity.Warning;

            return Severity.Error;
        }
    }
}