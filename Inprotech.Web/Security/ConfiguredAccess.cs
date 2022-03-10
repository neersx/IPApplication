using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Security
{
    public interface IConfiguredAccess
    {
        bool For(User user);
    }

    public class ConfiguredAccess : IConfiguredAccess
    {
        readonly IDbContext _dbContext;

        public ConfiguredAccess(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public bool For(User user)
        {
            /*
             * This call needs to be reviewed once Portal in Web Apps is implemented.
             */

            return user.IsValid && HasConfiguredAccessToPortal(user.Id);
        }

        bool HasConfiguredAccessToPortal(int id)
        {
            using (var command = _dbContext.CreateStoredProcedureCommand(Contracts.StoredProcedures.ListPortalTab))
            {
                command.CommandTimeout = 0;
                command.Parameters.AddWithValue("@pnUserIdentityId", id);
                using (var reader = command.ExecuteReader())
                {
                    return reader.Read() && reader.HasRows;
                }
            }
        }
    }
}