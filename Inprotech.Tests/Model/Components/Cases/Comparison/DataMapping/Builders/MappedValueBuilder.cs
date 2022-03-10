using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Ede.DataMapping;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class MappedValueBuilder : IBuilder<MappedValue>
    {
        public Source Source { get; set; }

        public string Output { get; set; }

        public MappedValue Build()
        {
            return
                new MappedValue(
                                Source ?? new SourceBuilder().Build(),
                                new Mapping
                                {
                                    OutputValue = Output
                                });
        }

        public MappedValueBuilder For(int type, string output = null, string code = null, string description = null)
        {
            Output = output;
            Source = new Source
            {
                Code = code,
                Description = description,
                TypeId = type
            };
            return this;
        }
    }
}