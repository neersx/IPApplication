using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.GroupMaintenance
{
    public class GroupMaintenanceDbSetUp : DbSetup
    {
        public const string GroupCode1 = "e2e";
        public const string GroupName1 = "e2e - group";
        public const string GroupCode2 = "g02";
        public const string GroupName2 = "g02 - group";
        public const string GroupCode3 = "g03";
        public const string GroupName3 = "g03 - group";
        public const string GroupCode4= "g04";
        public const string GroupName4 = "g04 - group";
        public const string GroupCode5 = "g05";
        public const string GroupName5 = "g05 - group";
        public const string CountryCode1 = "c01";
        public const string CountryName1 = "c01 - country";
        public const string CountryCode2 = "c02";
        public const string CountryName2 = "c02 - country";
        public const string CountryCode3 = "c03";
        public const string CountryName3 = "c03 - country";
        public const string CountryInternal = "ZZZ";
        public const string ValidProperty1 = "Patent";
        public const string ValidProperty2 = "Design";

        public void Prepare()
        {
            var nameStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.NameStyle).Id;
            var addressStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.AddressStyle).Id;

            DbContext.Set<Country>().Add(new Country(GroupCode1, GroupName1, "1"));
            DbContext.Set<Country>().Add(new Country(GroupCode2, GroupName2, "1"));
            DbContext.Set<Country>().Add(new Country(GroupCode3, GroupName3, "1"));
            DbContext.Set<Country>().Add(new Country(CountryCode1, CountryName1, "0") { PostalName = "g05g05", NameStyleId = nameStyleId, AddressStyleId = addressStyleId });

            var countryGroup4 = DbContext.Set<Country>().Add(new Country(GroupCode4, GroupName4, "1"));
            var countryGroup5 = DbContext.Set<Country>().Add(new Country(GroupCode5, GroupName5, "1"));
            var country = DbContext.Set<Country>().Add(new Country(CountryCode2, CountryName2, "0") { PostalName = "c02c02", NameStyleId = nameStyleId, AddressStyleId = addressStyleId });
            var countryInUse = DbContext.Set<Country>().Add(new Country(CountryCode3, CountryName3, "0") { PostalName = "c03c03" , NameStyleId = nameStyleId, AddressStyleId = addressStyleId });
            DbContext.Set<CountryGroup>().Add(new CountryGroup(countryGroup4, country));
            DbContext.Set<CountryGroup>().Add(new CountryGroup(countryGroup4, countryInUse));
            DbContext.Set<CountryGroup>().Add(new CountryGroup(countryGroup5, countryGroup4));

            var property = DbContext.Set<PropertyType>().ToArray();

            var caseType = DbContext.Set<CaseType>().First();
            var @case = DbContext.Set<Case>().Add(new Case(Fixture.String(5), countryGroup4, caseType, property.First()));
            @case.CountryId = countryGroup4.Id;
            DbContext.Set<RelatedCase>().Add(new RelatedCase(@case.Id, KnownRelations.DesignatedCountry1, countryInUse.Id));

            DbContext.Set<ValidProperty>().Add(new ValidProperty {CountryId = GroupCode1, PropertyName = ValidProperty1 , PropertyTypeId = "P"});
            DbContext.Set<ValidProperty>().Add(new ValidProperty { CountryId = GroupCode1, PropertyName = ValidProperty2, PropertyTypeId = "D" });
            DbContext.SaveChanges();
        }
    }
}
