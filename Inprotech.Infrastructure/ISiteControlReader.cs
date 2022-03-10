using System.Collections.Generic;

namespace Inprotech.Infrastructure
{
    public interface ISiteControlReader
    {
        T Read<T>(string name);
        
        Dictionary<string, T> ReadMany<T>(params string[] names);
    }
}