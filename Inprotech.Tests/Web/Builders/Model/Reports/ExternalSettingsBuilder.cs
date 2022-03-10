using System.ComponentModel.DataAnnotations.Schema;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Reports;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Reports
{
    public class ExternalSettingsBuilder : IBuilder<ExternalSettings>
    {
        public string ProviderName { get; set; }

        public string Settings { get; set; }

        //public bool IsComplete { get; set; }

        public ExternalSettings Build()
        {

            return new ExternalSettings(
                                        ProviderName
                                     ) {Settings = Settings};
        }
    }
}