using Inprotech.Tests.Integration.DbHelpers;
using Cases = InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.StatusType
{
    class StatusDbSetup : DbSetup
    {
        public const string StatusInternalDescription = "e2e - status";
        public const string StatusToBeAdded = StatusInternalDescription + " add";
        public const string StatusToBeEdit = StatusInternalDescription + " edit";
        public const string StatusToBeDuplicate = StatusInternalDescription + " duplicate";

        public ScenarioData Prepare()
        {
            var existingStatusType = InsertWithNewId(new Cases.Status
            {
                Name = StatusInternalDescription,
                RenewalFlag = 1,
                ExternalName = "e2e - external status"
            });

            return new ScenarioData
            {
                Name = existingStatusType.Name,
                ExternalName = existingStatusType.ExternalName,
                RenewalFlag = existingStatusType.IsRenewal,
                ExistingStatusType = existingStatusType
            };
        }

        public class ScenarioData
        {
            public string Name;
            public string ExternalName;
            public bool RenewalFlag;
            public Cases.Status ExistingStatusType;
        }
    }
}
