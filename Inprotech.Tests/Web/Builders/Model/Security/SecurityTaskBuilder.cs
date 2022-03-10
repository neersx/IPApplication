using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class SecurityTaskBuilder : IBuilder<SecurityTask>
    {
        public short? TaskId { get; set; }
        public string Name { get; set; }

        public SecurityTask Build()
        {
            return new SecurityTask(
                                    TaskId ?? Fixture.Short(),
                                    Name ?? Fixture.String()
                                   );
        }
    }
}