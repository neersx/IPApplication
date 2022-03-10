using System.Collections.Generic;

namespace Inprotech.Infrastructure.Notifications.Security
{
    public interface IUserAdministrators
    {
        IEnumerable<UserEmail> Resolve(int? identityId = null);
    }

    public class UserEmail
    {
        public int Id { get; set; }
        
        public string Email { get; set; }
    }
}
