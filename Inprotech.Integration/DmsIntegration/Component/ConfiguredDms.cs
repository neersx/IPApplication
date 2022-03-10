using System;
using Autofac.Features.Indexed;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using InprotechKaizen.Model;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public interface IConfiguredDms
    {
        (string Name, Type Type) GetSettingMetaData();

        IDmsService GetService();
    }

    public class ConfiguredDms : IConfiguredDms
    {
        readonly IIndex<string, IDmsService> _dmsServices;

        public ConfiguredDms(IIndex<string,IDmsService> dmsServices)
        {
            _dmsServices = dmsServices;
        }

        public (string Name, Type Type) GetSettingMetaData()
        {
            return (KnownExternalSettings.IManage, typeof(IManageSettings));
        }

        public IDmsService GetService()
        {
            return _dmsServices[KnownExternalSettings.IManage];
        }
    }
}