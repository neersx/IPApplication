using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class Features : IFeatures
    {
        public string[] Support => new[] {"settings", "cli-installation", "failed-action-recovery" };
    }
}