using System.Collections.Generic;

namespace Inprotech.Infrastructure.Localisation
{
    public interface IPreferredCultureSettings
    {
        IEnumerable<string> ResolveAll();
    }
}
