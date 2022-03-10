namespace Inprotech.Infrastructure.Security.ExternalApplications
{
    public class ExternalApplicationContext : IExternalApplicationContext
    {
        public string ExternalApplicationName { get; private set; }
        public void SetApplicationName(string externalApplicationName)
        {
            ExternalApplicationName = externalApplicationName.ToUpper();
        }
    }
}
