using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.System.Policy.AccessTracking
{
    class RegisterAccess : IRegisterAccess
    {
        readonly ISecurityContext _securityContext;
        readonly IDbContext _dbContext;

        abstract class Tables
        {
            public const string Cases = "CASES";
        }

        public RegisterAccess(ISecurityContext securityContext, IDbContext dbContext)
        {
            _securityContext = securityContext;
            _dbContext = dbContext;
        }

        public async Task ForCase(int rowKey)
        {
            await For(Tables.Cases, rowKey, null);
        }

        async Task For(string table, int? rowIntKey, string rowStrKey)
        {
            using (var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.RegisterAccess))
            {
                command.Parameters.AddWithValue("@pnUserIdentityId", _securityContext.User.Id);
                command.Parameters.AddWithValue("@psDatabaseTable", table);
                command.Parameters.AddWithValue("@pnIntegerKey", rowIntKey.HasValue
                                                    ? rowIntKey.Value
                                                    : DBNull.Value);
                command.Parameters.AddWithValue("@psCharacterKey", string.IsNullOrEmpty(rowStrKey)
                                                    ? DBNull.Value
                                                    : rowStrKey);
                await command.ExecuteNonQueryAsync();
            }
        }
    }
}