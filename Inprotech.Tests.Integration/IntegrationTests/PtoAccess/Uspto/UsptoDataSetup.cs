using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json.Linq;
using InprotechCase = InprotechKaizen.Model.Cases.Case;
using IntegrationCase = Inprotech.Integration.Case;

namespace Inprotech.Tests.Integration.IntegrationTests.PtoAccess.Uspto
{
    public class UsptoDataSetup : DbSetup
    {
        public Family CreateFamily()
        {
            return InsertWithNewId(new Family
            {
                Name = RandomString.Next(20) + "InnographyFamily"
            });
        }

        public InprotechCase BuildInprotechCase(string countryCode, string propertyType, Family family)
        {
            var caseType = DbContext.Set<CaseType>().Single(_ => _.Code == "A");
            var country = DbContext.Set<Country>().Single(_ => _.Id == countryCode);
            var property = DbContext.Set<PropertyType>().Single(_ => _.Code == propertyType);

            return InsertWithNewId(new InprotechCase(RandomString.Next(20), country, caseType, property)
            {
                Title = RandomString.Next(20),
                Family = family
            });
        }

        public UsptoDataSetup AddOfficialNumber(InprotechCase @case, string numberTypeCode, string number)
        {
            var numberType = DbContext.Set<NumberType>().Single(_ => _.NumberTypeCode == numberTypeCode);

            @case.OfficialNumbers.Add(new OfficialNumber(numberType, @case, number)
            {
                IsCurrent = 1
            });

            DbContext.SaveChanges();

            return this;
        }

        public void SetupExternalSettingsForPrivatePair()
        {
            var es = DbContext.Set<ExternalSettings>();
            var providerName = "InnographyPrivatePair";
            var settings = es.SingleOrDefault(_ => _.ProviderName == providerName) ??
                           es.Add(new ExternalSettings (providerName));

            #region setting

            settings.Settings = "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";

            #endregion

            settings.IsComplete = settings.Settings != null;
            DbContext.SaveChanges();
        }

        public void SetupExternalSettingsForPrivatePairEnvironmentOverride()
        {
            var es = DbContext.Set<ExternalSettings>();
            var providerName = "InnographyOverrides";
            var settings = es.SingleOrDefault(_ => _.ProviderName == providerName) ??
                           es.Add(new ExternalSettings (providerName));

            var settingsValue = JObject.Parse(settings.Settings ?? "{}");
            settingsValue["pp-env"] = DbContext.GetDbIdentifier();
            settings.Settings = settingsValue.ToString();

            settings.IsComplete = settings.Settings != null;
            DbContext.SaveChanges();
        }
    }
}