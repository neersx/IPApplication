using System.Configuration;


namespace Demogod
{
    public static class Connection
    {
        public static string String
        {
            get { return ConfigurationManager.ConnectionStrings["defaultConnection"].ConnectionString; }
        }
    }
}