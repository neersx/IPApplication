using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Reports;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Reports
{
    public class ExternalReportBuilder : IBuilder<ExternalReport>
    {
        public SecurityTask SecurityTask { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Path { get; set; }

        public ExternalReport Build()
        {
            var t = SecurityTask ?? new SecurityTaskBuilder().Build();

            return new ExternalReport(
                                      t,
                                      Title ?? Fixture.String(),
                                      Description ?? Fixture.String(),
                                      Path ?? Fixture.String()
                                     ) {TaskId = t.Id};
        }
    }
}