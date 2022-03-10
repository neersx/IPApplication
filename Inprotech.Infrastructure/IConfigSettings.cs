using System.Collections.Generic;
using Inprotech.Contracts.Settings;

namespace Inprotech.Infrastructure
{
    public interface IConfigSettings : ISettings
    {
        Dictionary<string, string> GetValues(params string[] settings);
    }
}