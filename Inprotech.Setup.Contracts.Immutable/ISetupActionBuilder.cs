using System.Collections.Generic;

namespace Inprotech.Setup.Contracts.Immutable
{
    public interface ISetupActionBuilder
    {
        IEnumerable<ISetupAction> BuildInstallActions();

        IEnumerable<ISetupAction> BuildUnInstallActions();

        IEnumerable<ISetupAction> BuildMaintenanceActions();

        IEnumerable<ISetupAction> BuildResyncActions();

        IEnumerable<ISetupAction> BuildPrepareForUpgradeActions();

        IEnumerable<ISetupAction> BuildUpgradeActions();
    }

    public interface ISetupActionBuilder2
    {
        IEnumerable<ISetupAction> BuildUpdateActions();
    }

    public interface ISetupActionBuilder3
    {
        IEnumerable<ISetupAction> BuildRecoveryActions(string failedActionForRecovery);
    }
}