using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class SourceBuilder : IBuilder<Source>
    {
        public string Code { get; set; }

        public string Description { get; set; }

        public int? TypeId { get; set; }

        public Source Build()
        {
            return new Source
            {
                Code = Code ?? Fixture.String(),
                Description = Description ?? Fixture.String(),
                TypeId = TypeId ?? Fixture.Integer()
            };
        }
    }
}