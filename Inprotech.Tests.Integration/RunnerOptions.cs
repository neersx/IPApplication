namespace Inprotech.Tests.Integration
{
    public static class RunnerOptions
    {
        public const string Servers = "Servers";
        public const string AgentRequirement = "AgentRequirement";

        public static class ServersOptions
        {
            public const string AustralianServers = "AU";
            public const string IndianServers = "IN";
            public const string AuthenticationTestServers = "Auth";
        }

        public class AgentRequirements
        {
            public const string UiBrowser = "UiBrowser";
        }

    }
}