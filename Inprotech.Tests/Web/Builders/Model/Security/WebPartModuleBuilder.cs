using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class WebPartModuleBuilder : IBuilder<WebpartModule>
    {
        public short? ModuleId { get; set; }
        public string Title { get; set; }

        public WebpartModule Build()
        {
            return new WebpartModule(
                                     ModuleId ?? Fixture.Short(),
                                     Title ?? Fixture.String()
                                    );
        }
    }
}