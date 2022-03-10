using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class OfficialNumberBuilder : IBuilder<OfficialNumber>
    {
        public string Code { get; set; }

        public string NumberType { get; set; }

        public string Number { get; set; }

        public OfficialNumber Build()
        {
            return new OfficialNumber
            {
                Code = Code,
                Number = Number,
                NumberType = NumberType
            };
        }
    }
}