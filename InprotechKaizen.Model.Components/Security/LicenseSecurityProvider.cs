using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using Inprotech.Infrastructure.Security.Licensing;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Security
{
    public class LicenseSecurityProvider : ILicenseSecurityProvider
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public LicenseSecurityProvider(IDbContext dbContext, ISecurityContext securityContext)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if (securityContext == null) throw new ArgumentNullException(nameof(securityContext));

            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public Dictionary<int, LicenseData> ListUserLicenses()
        {
            var sqlCommand = _dbContext.CreateStoredProcedureCommand("sc_ListUserLicenses");
            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               new SqlParameter("@pnIdentityKey", _securityContext.User.Id),
                                               new SqlParameter("@pnModuleFlag", Model.Security.KnownValues.Licensing.WebModules)
                                           });

            var userLicenses = new Dictionary<int, LicenseData>();

            using (IDataReader reader = sqlCommand.ExecuteReader())
            {
                while (reader.Read())
                {
                    var licenseModuleKey = reader.GetInt32(0);
                    var licenseName = reader.GetString(1);
                    var isLicensed = reader.GetBoolean(2);
                    if (!isLicensed) continue;
                    DateTime? expiry = null;
                    if (!reader.IsDBNull(3))
                        expiry = reader.GetDateTime(3);

                    userLicenses.Add(
                                     licenseModuleKey,
                                     new LicenseData(licenseModuleKey, licenseName, expiry));
                }

                return userLicenses;
            }
        }

        public bool IsLicensedForModules(List<LicensedModule> licensedModules)
        {
            var userLicenses = ListUserLicenses();
            return userLicenses.Any(a =>
                                        licensedModules.Any(b => (int) b == a.Key));
        }
    }
}