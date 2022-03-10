using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class ImportanceBuilder : IBuilder<Importance>
    {
        public string ImportanceLevel { get; set; }
        public string ImportanceLevelDescription { get; set; }

        public Importance Build()
        {
            return new Importance
            {
                Level = ImportanceLevel ?? "1",
                Description = ImportanceLevelDescription ?? Fixture.String()
            };
        }
    }
}