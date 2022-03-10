using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Relationship
{
    class RelationshipPicklistDbSetUp : DbSetup
    {
        public const string RelationshipPrefix = "e2e - relationship";
        public const string ExistingRelationship = RelationshipPrefix + " existing";
        public const string ExistingRelationship2 = ExistingRelationship + "2";
        public const string ExistingRelationship3 = ExistingRelationship + "3";
        public const string RelationshipToBeAdded = RelationshipPrefix + " add";

        public ScenarioData DataSetUp()
        {
            var existingRelationship = AddRelationship("ABC", ExistingRelationship);
            AddRelationship("DEF", ExistingRelationship2);
            AddRelationship("GHI", ExistingRelationship3);
            var existingEvent = DbContext.Set<InprotechKaizen.Model.Cases.Events.Event>().FirstOrDefault();

            return new ScenarioData
                   {
                       RelationshipId = existingRelationship.Relationship,
                       RelationshipName = existingRelationship.Description,
                       ExistingRelationship = existingRelationship,
                       ExistingEvent = existingEvent
                   };
        }

        public CaseRelation AddRelationship(string id, string description)
        {
            var relationship = DbContext.Set<CaseRelation>().FirstOrDefault(_ => _.Relationship == id);
            if (relationship != null)
                return relationship;

            relationship = new CaseRelation(id, description, null);

            DbContext.Set<CaseRelation>().Add(relationship);
            DbContext.SaveChanges();

            return relationship;
        }

        public void AddValidRelationship(CaseRelation caseRelation)
        {
            var country = DbContext.Set<Country>().FirstOrDefault();
            var propertyType = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().FirstOrDefault();
            var validRelationship = new ValidRelationship(country, propertyType, caseRelation);

            DbContext.Set<ValidRelationship>().Add(validRelationship);
            DbContext.SaveChanges();
        }

        public class ScenarioData
        {
            public CaseRelation ExistingRelationship;
            public string RelationshipId;
            public string RelationshipName;
            public InprotechKaizen.Model.Cases.Events.Event ExistingEvent;
        }
    }
}
