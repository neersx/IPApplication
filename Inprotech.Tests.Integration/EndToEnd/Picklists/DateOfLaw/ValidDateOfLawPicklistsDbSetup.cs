using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.DateOfLaw
{
    public class ValidDateOfLawPicklistsDbSetup : DbSetup
    {
        internal const string ActionDescription1 = "e2e - Action1";
        internal const string ActionDescription2 = "e2e - Action2";
        internal const string JurisdictionDescription = "e2e - jurisdiction";
        internal const string PropertyTypeDescription = "e2e - property type";
        internal const string PropertyTypeDescription2 = PropertyTypeDescription + "2";
        internal const string LawEventDescription = "e2e - law event";
        internal const string RetroEventDescription = "e2e - retro event";
        internal const string LawEventDescription1 = "e3e - law event";
        internal const string RetroEventDescription1 = "e3e - retro event";

        public dynamic PrepareValidDateOfLawData()
        {
            var jurisdiction = DbContext.Set<Country>().SingleOrDefault(_ => _.Name == JurisdictionDescription) ??
                                DbContext.Set<Country>().Add(new Country("e2e", JurisdictionDescription, "0") { AllMembersFlag = 0 });

            var propertyType = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().SingleOrDefault(_ => _.Name == PropertyTypeDescription) ??
                               DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().Add(new InprotechKaizen.Model.Cases.PropertyType("_", PropertyTypeDescription));

            Insert(new ValidProperty { CountryId = jurisdiction.Id, PropertyTypeId = propertyType.Code, PropertyName = "v" + propertyType.Name });

            var action1 = InsertWithNewId(new InprotechKaizen.Model.Cases.Action { Name = ActionDescription1 });
            var action2 = InsertWithNewId(new InprotechKaizen.Model.Cases.Action { Name = ActionDescription2 });

            var lawEvent = InsertWithNewId(new InprotechKaizen.Model.Cases.Events.Event { Description = LawEventDescription });
            InsertWithNewId(new InprotechKaizen.Model.Cases.Events.Event { Description = LawEventDescription1 });

            var retroEvent = InsertWithNewId(new InprotechKaizen.Model.Cases.Events.Event { Description = RetroEventDescription });
            InsertWithNewId(new InprotechKaizen.Model.Cases.Events.Event { Description = RetroEventDescription1 });

            var dateTime = new DateTime(2011, 6, 6);
            var dateOfLaw1 = new InprotechKaizen.Model.ValidCombinations.DateOfLaw
            {
                PropertyType = propertyType,
                Country = jurisdiction,
                SequenceNo = 0,
                Date = dateTime,
                RetroAction = null,
                LawEvent = lawEvent,
                RetroEvent = retroEvent
            };

            var dateOfLaw2 = new InprotechKaizen.Model.ValidCombinations.DateOfLaw
            {
                PropertyType = propertyType,
                Country = jurisdiction,
                SequenceNo = 1,
                Date = dateTime,
                RetroAction = action1,
                LawEvent = lawEvent,
                RetroEvent = retroEvent
            };

            var dateOfLaw3 = new InprotechKaizen.Model.ValidCombinations.DateOfLaw
            {
                PropertyType = propertyType,
                Country = jurisdiction,
                SequenceNo = 2,
                Date = dateTime,
                RetroAction = action2,
                LawEvent = lawEvent,
                RetroEvent = retroEvent
            };

            DbContext.Set<InprotechKaizen.Model.ValidCombinations.DateOfLaw>().Add(dateOfLaw1);
            DbContext.Set<InprotechKaizen.Model.ValidCombinations.DateOfLaw>().Add(dateOfLaw2);
            DbContext.Set<InprotechKaizen.Model.ValidCombinations.DateOfLaw>().Add(dateOfLaw3);

            InsertWithNewId(new Criteria
            {
                Description = Fixture.Prefix(Fixture.String(3)),
                PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                CountryId = jurisdiction.Id,
                PropertyTypeId = propertyType.Code,
                DateOfLaw = dateOfLaw1.Date

            });

            DbContext.SaveChanges();

            return new 
            {
                dateOfLaw1.Date
            };
        }
        
    }
}
