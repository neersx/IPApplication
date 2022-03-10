using System.Collections.Generic;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Security
{
    public interface IAllowableProgramsResolver
    {
        Task<IEnumerable<string>> Resolve();
    }
}
