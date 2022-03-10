using System.Collections.Generic;

namespace Inprotech.Infrastructure.Web
{
    public interface IComponent
    {
        Dictionary<string,int> Components { get; }
    }
}
