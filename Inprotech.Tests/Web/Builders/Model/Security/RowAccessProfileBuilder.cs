using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class RowAccessProfileBuilder
    {
        public string Name { get; set; }

        public RowAccess Build()
        {
            return new RowAccess(Name ?? Fixture.String(), Fixture.String());
        }
    }
}