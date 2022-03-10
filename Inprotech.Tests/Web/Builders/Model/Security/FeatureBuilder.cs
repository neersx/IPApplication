using Inprotech.Tests.Web.Builders.Model.Configuration;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class FeatureBuilder : IBuilder<Feature>
    {
        public short? Id { get; set; }
        public string Name { get; set; }
        public TableCode Category { get; set; }
        public bool? IsExternal { get; set; }
        public bool? IsInternal { get; set; }

        public Feature Build()
        {
            return new Feature(
                               Id ?? Fixture.Short(),
                               Name ?? Fixture.String(),
                               Category ?? new TableCodeBuilder().Build(),
                               IsExternal ?? Fixture.Boolean(),
                               IsInternal ?? Fixture.Boolean()
                              );
        }
    }
}