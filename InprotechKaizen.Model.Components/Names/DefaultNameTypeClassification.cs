using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Names
{
    public interface IDefaultNameTypeClassification
    {
        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        IEnumerable<ValidNameTypeClassification> FetchNameTypeClassification(int? usedAsFlag, int? nameId = null);
    }

    public class DefaultNameTypeClassification : IDefaultNameTypeClassification
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public DefaultNameTypeClassification(IDbContext dbContext, ISecurityContext securityContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (securityContext == null) throw new ArgumentNullException("securityContext");

            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public IEnumerable<ValidNameTypeClassification> FetchNameTypeClassification(int? usedAsFlag, int? nameId = null)
        {
            var sqlCommand = _dbContext.CreateStoredProcedureCommand("naw_FetchNameTypeClassification");
            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                               new SqlParameter("@psCulture", null),
                                               new SqlParameter("@pnNameKey", nameId),
                                               new SqlParameter("@pnUsedAsFlag", usedAsFlag),
                                               new SqlParameter("@pbCalledFromCentura", false)
                                           });

            var result = new List<ValidNameTypeClassification>();

            using (var reader = sqlCommand.ExecuteReader())
            {
                while (reader.Read())
                    result.Add(new ValidNameTypeClassification
                               {
                                   NameTypeKey = reader["NameTypeKey"].ToString(),
                                   IsSelected = Convert.ToBoolean(reader["IsSelected"]),
                                   IsCrmOnly = Convert.ToBoolean(reader["IsCRMOnly"])
                               });

                return result;
            }
        }
    }
}