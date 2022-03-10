namespace InprotechKaizen.Model.Components.Queries
{
    public static class SearchHelper
    {
        public static string GetOperatorMapping(this string value)
        {
            switch (value)
            {
                case "in": return "0";
                case "notIn": return "1";
                default: return string.Empty;
            }
        }
    }
}