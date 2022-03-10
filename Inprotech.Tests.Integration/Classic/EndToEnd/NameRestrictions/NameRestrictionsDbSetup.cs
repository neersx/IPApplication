using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.NameRestrictions
{
    class NameRestrictionsDbSetup : DbSetup
    {
        public const string NameRestrictionDescription = "e2e - namerestriction";
        public const string NameRestrictionToBeAdded = NameRestrictionDescription + " add";
        public const string NameRestrictionToBeEdit = NameRestrictionDescription + " edit";
        public const string NameRestrictionToBeDuplicate = NameRestrictionDescription + " duplicate";
        public const string NameRestrictionToBeDelete = " e2e - Absolutely";

        public ScenarioData Prepare()
        {
            var id = DbContext.Set<DebtorStatus>().Any() ? DbContext.Set<DebtorStatus>().Max(m => m.Id) : (short)0;
            id++;
            InsertWithNewId(new DebtorStatus(id)
            {
                Status = NameRestrictionDescription,
                RestrictionType = 3
            });
            id++;
            var existingNameRestriction = InsertWithNewId(new DebtorStatus(id)
            {
                Status = NameRestrictionToBeDelete,
                RestrictionType = 3
            });

            var lastinternalCode = DbContext.Set<LastInternalCode>().First(_ => _.TableName.Equals("DEBTORSTATUS"));
            lastinternalCode.InternalSequence = id;
            DbContext.SaveChanges();

            return new ScenarioData
            {
                Status = existingNameRestriction.Status,
                RestrictionType = existingNameRestriction.RestrictionType,
                ExistingApplicationNameRestrictions = existingNameRestriction
            };
        }

        public class ScenarioData
        {
            public string Status;
            public decimal? RestrictionType;
            public DebtorStatus ExistingApplicationNameRestrictions;
        }
    }
}