using Inprotech.Tests.Integration.DbHelpers;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.NameRelation
{
    class NameRelationDbSetup : DbSetup
    {
        public const string RelationShipCode = "E2E";
        public const string RelationShipDescription = "E3E RelationShipDes";
        public const string ReverseRelationShipDescription = "E3E ReverseRelationShipDesc";
        public const bool IsEmployee = true;
        public const bool IsIndividual = false;
        public const bool IsOrganisation = false;
        public const bool IsCrmOnly = true;

        public ScenarioData Prepare()
        {
            var nameRelationsModel = new Web.Configuration.Names.NameRelationsModel
            {
                RelationshipCode = RelationShipCode,
                RelationshipDescription = RelationShipDescription,
                ReverseDescription = ReverseRelationShipDescription,
                IsEmployee = IsEmployee,
                IsIndividual = IsIndividual,
                IsOrganisation = IsOrganisation,
                IsCrmOnly = IsCrmOnly,
                EthicalWall = "2",
                EthicalWallValue = "Deny Access"
            };

            var namerelation = InsertWithNewId(new InprotechKaizen.Model.Names.NameRelation()
            {
                RelationshipCode = "TES",
                ReverseDescription = "REVTES",
                RelationDescription = "TES",
                UsedByNameType = 4,
                EthicalWall = 2
            });
            
            InsertWithNewId(new InprotechKaizen.Model.Cases.NameType
            {
                PathNameRelation = namerelation
            });

            return new ScenarioData
            {
                UsedNameRelation = namerelation,
                NameRelationsModel = nameRelationsModel
            };
        }

        public class ScenarioData
        {
            public InprotechKaizen.Model.Names.NameRelation UsedNameRelation { get; set; }
            public Web.Configuration.Names.NameRelationsModel NameRelationsModel { get; set; }
        }
    }
}
