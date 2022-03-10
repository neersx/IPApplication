using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Security.ExternalApplications
{
    public interface IUserValidator
    {
        Task<bool> ValidateUser(string loginId);
    }
}