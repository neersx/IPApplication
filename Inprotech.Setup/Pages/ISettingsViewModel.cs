using System.Collections.Generic;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Pages
{
    public interface ISettingsViewModel
    {
        void SetInstanceDetails(InstanceDetails instanceDetails);

        void SetSetupSettings(Dictionary<string, string> settings);
    }
}