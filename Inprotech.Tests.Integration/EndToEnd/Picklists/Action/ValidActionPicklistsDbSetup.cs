using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Action
{
    public class ValidActionPicklistsDbSetup : DbSetup
    {
        public const string ActionPrefix = "e2e - valid action";
        internal const string CaseTypeDescription = "e2e - case type";
        internal const string JurisdictionDescription = "e2e - jurisdiction";
        internal const string JurisdictionDescription2 = "e2e - jurisdiction 2";
        internal const string PropertyTypeDescription = "e2e - property type";
        internal const string PropertyTypeDescription2 = PropertyTypeDescription + "2";
        internal const string ValidPropertyTypeDescription = "e2e - valid property type";
        internal const string ActionDescription = "e2e - action";
        internal const string ValidActionDescription = ActionPrefix;
        internal const string ValidActionDescriptionEdited = ActionPrefix + " edited";
        internal const string DuplicateActionDescription = ActionPrefix + " duplicate";

        public void Prepare()
        {
            PrepareValidCharacteristics();
        }

        void PrepareValidCharacteristics()
        {
            if (DbContext == null) return;

            if (!DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().Any(_ => _.Name == CaseTypeDescription))
            {
                DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().Add(new InprotechKaizen.Model.Cases.CaseType("_", CaseTypeDescription));
            }

            var jurisdiction = DbContext.Set<Country>().SingleOrDefault(_ => _.Name == JurisdictionDescription) ??
                               DbContext.Set<Country>().Add(new Country("e2e", JurisdictionDescription, "0") { AllMembersFlag = 0 });

            var jurisdiction2 = DbContext.Set<Country>().SingleOrDefault(_ => _.Name == JurisdictionDescription2) ??
                               DbContext.Set<Country>().Add(new Country("e3e", JurisdictionDescription2, "0") { AllMembersFlag = 0 });

            var propertyType = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().SingleOrDefault(_ => _.Name == PropertyTypeDescription) ??
                               DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().Add(new InprotechKaizen.Model.Cases.PropertyType("_", PropertyTypeDescription));

            if (!DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().Any(_ => _.Name == PropertyTypeDescription2))
            {
                DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().Add(new InprotechKaizen.Model.Cases.PropertyType("!", PropertyTypeDescription2));
            }

            if (!DbContext.Set<InprotechKaizen.Model.Cases.Action>().Any(_ => _.Name == ActionDescription))
            {
                DbContext.Set<InprotechKaizen.Model.Cases.Action>().Add(new InprotechKaizen.Model.Cases.Action(id: "e2", name: ActionDescription));
            }

            if(!DbContext.Set<InprotechKaizen.Model.Cases.Action>().Any(_ => _.Name == DuplicateActionDescription))
                         DbContext.Set<InprotechKaizen.Model.Cases.Action>().Add(new InprotechKaizen.Model.Cases.Action(id: "e3", name: DuplicateActionDescription));

            DbContext.SaveChanges();

            if (!DbContext.Set<ValidProperty>().Any(_ => _.PropertyName == ValidPropertyTypeDescription))
            {
                DbContext.Set<ValidProperty>().Add(new ValidProperty
                {
                    CountryId = jurisdiction.Id,
                    PropertyTypeId = propertyType.Code,
                    PropertyName = ValidPropertyTypeDescription
                });

                DbContext.Set<ValidProperty>().Add(new ValidProperty
                {
                    CountryId = jurisdiction2.Id,
                    PropertyTypeId = propertyType.Code,
                    PropertyName = ValidPropertyTypeDescription
                });
            }

            DbContext.SaveChanges();
        }
    }
}