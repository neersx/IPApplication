using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class TelecommunicationBuilder : IBuilder<Telecommunication>
    {
        public string Isd { get; set; }

        public string AreaCode { get; set; }

        public string TelecomNumber { get; set; }

        public string Extension { get; set; }

        public TableCode TelecomType { get; set; }

        public Telecommunication Build()
        {
            return new Telecommunication(Fixture.Integer())
            {
                AreaCode = AreaCode,
                Isd = Isd,
                TelecomNumber = TelecomNumber,
                Extension = Extension,
                TelecomType = TelecomType
            };
        }
    }
}