using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Security
{
    public interface IRegisterAccess
    {
        Task ForCase(int rowKey);
    }
}