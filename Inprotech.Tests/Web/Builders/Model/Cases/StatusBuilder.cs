using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class StatusBuilder : IBuilder<Status>
    {
        public short? Id { get; set; }
        public string Name { get; set; }
        public bool IsLive { get; set; }
        public bool IsRegistered { get; set; }
        public bool IsRenewalStatus { get; set; }
        public bool? PreventWip { get; set; }

        public Status Build()
        {
            return new Status(Id ?? Fixture.Short(), Name ?? Fixture.String("Name"))
            {
                LiveFlag = IsLive ? 1 : 0,
                RegisteredFlag = IsRegistered ? 1 : 0,
                RenewalFlag = IsRenewalStatus ? 1 : 0,
                PreventWip = PreventWip
            };
        }
    }

    public static class StatusBuilderEx
    {
        public static StatusBuilder ForRenewal(this StatusBuilder statusBuilder)
        {
            statusBuilder.IsRenewalStatus = true;
            return statusBuilder;
        }

        public static StatusBuilder WithWipRestriction(this StatusBuilder statusBuilder)
        {
            statusBuilder.PreventWip = true;
            return statusBuilder;
        }
    }
}