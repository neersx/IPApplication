namespace InprotechKaizen.Model.Components.Configuration.Rules
{
    public class CriteriaMatchOptions
    {
        public const string ExactMatch = "exact-match";
        public const string BestMatch = "best-match";
        public const string BestCriteriaOnly = "best-criteria-only";
    }

    public class ClientFilterOptions
    {
        public const string Na = null;
        public const string LocalClients = "local-clients";
        public const string ForeignClients = "foreign-clients";

        public static string Convert(decimal? flag)
        {
            if (!flag.HasValue)
                return Na;

            return flag == 1 ? LocalClients : ForeignClients;
        }
    }
}