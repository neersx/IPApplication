using System.Collections.Generic;

namespace Inprotech.Infrastructure.Security
{
    public interface ITaskAuthorisation
    {
        bool Authorize(
            IEnumerable<RequiresAccessToAttribute> actionAttributes,
            IEnumerable<RequiresAccessToAttribute> controllerAttributes);
    }
}