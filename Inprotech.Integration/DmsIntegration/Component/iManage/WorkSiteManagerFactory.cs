using System;
using Autofac.Features.Indexed;
using Inprotech.Integration.DmsIntegration.Component.Domain;

namespace Inprotech.Integration.DmsIntegration.Component.iManage
{
    public interface IWorkSiteManagerFactory
    {
        IWorkSiteManager GetWorkSiteManager(IManageSettings.SiteDatabaseSettings setting);
    }

    public class WorkSiteManagerFactory : IWorkSiteManagerFactory
    {
        readonly IIndex<Version, Func<IWorkSiteManager>> _workSiteMgrMap;

        public WorkSiteManagerFactory(IIndex<Version, Func<IWorkSiteManager>> workSiteMgrMap)
        {
            _workSiteMgrMap = workSiteMgrMap;
        }

        public IWorkSiteManager GetWorkSiteManager(IManageSettings.SiteDatabaseSettings setting)
        {
            if (setting.IntegrationType == IManageSettings.IntegrationTypes.iManageWorkApiV1)
            {
                return _workSiteMgrMap[Version.WorkApiV1]();
            }

            if (setting.IntegrationType == IManageSettings.IntegrationTypes.iManageWorkApiV2)
            {
                return _workSiteMgrMap[Version.WorkApiV2]();
            }

            if (setting.IntegrationType == IManageSettings.IntegrationTypes.iManageCOM)
            {
                return _workSiteMgrMap[Version.iManageCom]();
            }

            if (setting.IntegrationType == IManageSettings.IntegrationTypes.Demo)
            {
                return _workSiteMgrMap[Version.Demo]();
            }

            return null;
        }
    }
}
