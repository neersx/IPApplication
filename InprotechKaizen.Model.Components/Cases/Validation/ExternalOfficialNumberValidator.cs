using System;
using System.Data;
using System.Data.SqlClient;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Validation
{
    public interface IExternalOfficialNumberValidator
    {
        ExternalOfficialNumberValidatorResult ValidateOfficialNumber(int caseId, string numberType, string officialNumber);
    }

    public class ExternalOfficialNumberValidator : IExternalOfficialNumberValidator
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public ExternalOfficialNumberValidator(IDbContext dbContext, ISecurityContext securityContext)
        {
            if(dbContext == null) throw new ArgumentNullException("dbContext");
            if(securityContext == null) throw new ArgumentNullException("securityContext");
            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public ExternalOfficialNumberValidatorResult ValidateOfficialNumber(
            int caseId,
            string numberType,
            string officialNumber)
        {
            var sqlCommand = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.ValidateOfficialNumber);
            sqlCommand.CommandTimeout = 0;

            var patternError = new SqlParameter("@pnPatternError", SqlDbType.Int)
                               {
                                   Direction = ParameterDirection.Output
                               };
            var errorMessage = new SqlParameter("@psErrorMessage", SqlDbType.NVarChar, 254)
                               {
                                   Direction = ParameterDirection.Output
                               };
            var warningFlag = new SqlParameter("@pnWarningFlag", SqlDbType.TinyInt)
                              {Direction = ParameterDirection.Output};

            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               patternError,
                                               errorMessage,
                                               warningFlag,
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                               new SqlParameter("@psCulture", null),
                                               new SqlParameter("@pnCaseId", caseId),
                                               new SqlParameter("@psNumberType", numberType),
                                               new SqlParameter("@psOfficialNumber", officialNumber)
                                           });

            sqlCommand.ExecuteNonQuery();

            return new ExternalOfficialNumberValidatorResult
                   {
                       ErrorCode = (int)patternError.Value,
                       ErrorMessage = errorMessage.Value != DBNull.Value ? (string)errorMessage.Value : null,
                       WarningFlag = (byte)warningFlag.Value
                   };
        }
    }
}