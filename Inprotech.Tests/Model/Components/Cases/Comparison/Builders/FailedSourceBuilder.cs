using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Builders
{
    public class FailedSourceBuilder : IBuilder<FailedSource>
    {
        public int? TypeId { get; set; }

        public string Name { get; set; }

        public string Code { get; set; }

        public string Description { get; set; }

        public FailedSource Build()
        {
            return new FailedSource(new Source
                                    {
                                        TypeId = TypeId ?? Fixture.Integer(),
                                        Code = Code ?? Fixture.String(),
                                        Description = Description ?? Fixture.String()
                                    }, Name ?? Fixture.String());
        }
    }
}