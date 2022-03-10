using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Security
{
    public interface ILicenses
    {
        LicenseVerification Verify(int userId);
        Task<IEnumerable<ExpiringLicense>> Expiring();
    }

    public class Licenses : ILicenses
    {
        readonly IDbContext _dbContext;

        public Licenses(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public LicenseVerification Verify(int userId)
        {
            using (var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.VerifyLicenses))
            {
                command.Parameters.AddRange(
                                            new[]
                                            {
                                                new SqlParameter("@pnUserIdentityId", userId),
                                                new SqlParameter("@pnModuleFlag", Model.Security.KnownValues.Licensing.WebModules),
                                                new SqlParameter("@psModule", SqlDbType.NVarChar, 100) {Direction = ParameterDirection.Output},
                                                new SqlParameter("@pbBlockUser", SqlDbType.Bit) {Direction = ParameterDirection.Output},
                                                new SqlParameter("@pnFailReason", SqlDbType.TinyInt) {Direction = ParameterDirection.Output}
                                            });

                command.ExecuteNonQuery();

                var failReason = command.Parameters["@pnFailReason"].Value;
                return failReason == DBNull.Value
                    ? new LicenseVerification()
                    : new LicenseVerification
                      {
                          UnlicensedModule = command.Parameters["@psModule"].Value == DBNull.Value
                              ? null
                              : (string) command.Parameters["@psModule"].Value,
                          IsBlocked = (bool) command.Parameters["@pbBlockUser"].Value,
                          FailReason = (FailReason) (byte) failReason
                      };
            }
        }

        public async Task<IEnumerable<ExpiringLicense>> Expiring()
        {
            var licenses = new List<ExpiringLicense>();

            using (var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.ListExpiringLicenses))
            {
                command.Parameters.AddWithValue("@pnUserIdentityId", int.MinValue);
                command.Parameters.AddWithValue("@pnModuleFlag", Model.Security.KnownValues.Licensing.WebModules);

                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (reader.Read())
                        licenses.Add(new ExpiringLicense
                                     {
                                         Module = reader.GetString(0),
                                         ExpiryDate = reader.GetDateTime(1)
                                     });
                }
            }

            return licenses;
        }
    }

    public enum FailReason
    {
        // Only the below fail reasons are implemented in the web modules.
        ExceededUsers = 3,
        NoLicenceFound = 20
    }

    public class LicenseVerification
    {
        public string UnlicensedModule { get; set; }

        public FailReason FailReason { get; set; }

        public bool IsBlocked { get; set; }
    }

    public class ExpiringLicense
    {
        public string Module { get; set; }

        public DateTime ExpiryDate { get; set; }
    }
}