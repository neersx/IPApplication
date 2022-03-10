using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using System.Linq;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.PropertyType
{
    public class ValidPropertyTypeDbSetup : DbSetup
    {
        public const string PropertyTypePrefix = "e2e - valid property type";
        internal const string JurisdictionDescription = "e2e - jurisdiction";
        internal const string JurisdictionDescription2 = "e2e - jurisdiction 2";
        internal const string ValidPropertyTypeDescription = PropertyTypePrefix;
        internal const string ValidPropertyTypeEdited = PropertyTypePrefix + " edited";
        internal const string DuplicateValidPropertyType = PropertyTypePrefix + " duplicate";

        public void Prepare()
        {
            PrepareValidCharacteristics();
        }

        void PrepareValidCharacteristics()
        {
            if (DbContext == null) return;

            if(!DbContext.Set<Country>().Any(_ => _.Name == JurisdictionDescription))
                DbContext.Set<Country>().Add(new Country("e2e", JurisdictionDescription, "0") { AllMembersFlag = 0 });

            if(!DbContext.Set<Country>().Any(_ => _.Name == JurisdictionDescription2))
                DbContext.Set<Country>().Add(new Country("e3e", JurisdictionDescription2, "0") { AllMembersFlag = 0 });

            if(!DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().Any(_ => _.Name == ValidPropertyTypeDescription))
                DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().Add(new InprotechKaizen.Model.Cases.PropertyType("_", ValidPropertyTypeDescription));

            if(!DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().Any(_ => _.Name == DuplicateValidPropertyType))
                DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().Add(new InprotechKaizen.Model.Cases.PropertyType("@", DuplicateValidPropertyType));
            
            DbContext.SaveChanges();
        }

    }
}
